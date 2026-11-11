import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Hasil ekstraksi payload QRIS dari halaman DOKU Checkout.
class ExtractedQrisPayload {
  final String? qrString;
  final Uint8List? imageBytes;
  final String? imageUrl;

  const ExtractedQrisPayload({
    this.qrString,
    this.imageBytes,
    this.imageUrl,
  });

  bool get hasQrString => qrString != null && qrString!.trim().isNotEmpty;
  bool get hasImageBytes => imageBytes != null && imageBytes!.isNotEmpty;
  bool get hasImageUrl => imageUrl != null && imageUrl!.trim().isNotEmpty;
  bool get isValid => hasQrString || hasImageBytes || hasImageUrl;
}

/// Utilitas murni untuk mengekstrak EMVCo QRIS string, gambar base64, atau URL gambar QR
/// dari teks, JSON API DOKU Checkout, atau DOM WebView.
class DokuQrPayloadParser {
  DokuQrPayloadParser._();

  static final RegExp _emvQrRegex = RegExp(
    r'000201[^\x00-\x1F"<>\\]{28,}6304[0-9A-Fa-f]{4}',
  );

  static bool isDokuFinishUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('finish') ||
        lower.contains('settlement') ||
        lower.contains('status_code=200') ||
        lower.contains('status=success') ||
        lower.contains('status=settlement') ||
        lower.contains('transaction_status=settlement');
  }

  /// Normalisasi karakter escape JSON umum agar regex EMVCo dapat membacanya secara utuh.
  static String _unescapePayloadText(String rawText) {
    return rawText
        .replaceAll(r'\/', '/')
        .replaceAll(r'\u002f', '/')
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\u003d', '=')
        .replaceAll(r'\u003D', '=')
        .replaceAll(r'\"', '"')
        .replaceAll(RegExp(r'[\r\n\t]+'), '');
  }

  /// Mengambil string EMVCo QRIS standar BI/ASPI (diawali 000201 dan diakhiri 6304XXXX).
  static String? extractEmvQrString(String rawText) {
    if (rawText.trim().isEmpty) return null;

    final unescaped = _unescapePayloadText(rawText);
    final match = _emvQrRegex.firstMatch(unescaped);
    if (match == null) return null;

    var candidate = match.group(0)?.trim() ?? '';
    if (candidate.startsWith('"') && candidate.endsWith('"') && candidate.length > 2) {
      candidate = candidate.substring(1, candidate.length - 1).trim();
    }
    if (candidate.length < 40 || candidate.length > 1024) return null;
    if (!candidate.startsWith('000201')) return null;

    return candidate;
  }

  /// Mendecode `data:image/...;base64,...` atau base64 PNG/JPEG mentah menjadi Uint8List.
  static Uint8List? decodeDataImageBytes(String rawDataUri) {
    final trimmed = rawDataUri.trim();
    if (trimmed.isEmpty) return null;

    var base64Part = trimmed;
    if (trimmed.startsWith('data:image/')) {
      final commaIdx = trimmed.indexOf(',');
      if (commaIdx == -1) return null;
      base64Part = trimmed.substring(commaIdx + 1).trim();
    }

    // Tolak placeholder kosong 1x1 transparan atau payload terlalu pendek.
    if (base64Part.length < 120) return null;

    try {
      final bytes = base64Decode(base64Part);
      if (bytes.length < 80) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Memvalidasi URL gambar QR yang aman (http/https).
  static String? sanitizeQrImageUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasAuthority) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return trimmed;
  }

  /// Mem-parsing pesan JSON dari JavaScriptChannel WebView menjadi `ExtractedQrisPayload`.
  static ExtractedQrisPayload? parseBridgeMessage(String rawMessage) {
    final trimmed = rawMessage.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final type = (decoded['type'] ?? '').toString().toLowerCase();
        final value = (decoded['value'] ?? '').toString();

        if (type == 'emv' || type == 'text') {
          final qr = extractEmvQrString(value);
          if (qr != null) return ExtractedQrisPayload(qrString: qr);
        }

        if (type == 'image') {
          final bytes = decodeDataImageBytes(value);
          if (bytes != null) return ExtractedQrisPayload(imageBytes: bytes);
        }

        if (type == 'image_url') {
          final safeUrl = sanitizeQrImageUrl(value);
          if (safeUrl != null) return ExtractedQrisPayload(imageUrl: safeUrl);
        }
      }
    } catch (_) {
      // Fallback: perlakukan pesan sebagai string mentah.
    }

    final emvFallback = extractEmvQrString(trimmed);
    if (emvFallback != null) {
      return ExtractedQrisPayload(qrString: emvFallback);
    }

    final bytesFallback = decodeDataImageBytes(trimmed);
    if (bytesFallback != null) {
      return ExtractedQrisPayload(imageBytes: bytesFallback);
    }

    return null;
  }
}

/// Mengelola WebView DOKU Checkout di latar/inline untuk mengekstrak QRIS secara otomatis
/// sekaligus menyediakan tampilan QRIS inline di halaman Pembayaran QRIS aplikasi ini.
class DokuQrisWebController {
  WebViewController? _controller;
  Timer? _domPollTimer;
  int _domPollCount = 0;
  bool _disposed = false;
  bool _resolvedDirectQr = false;
  bool _isLoading = true;
  bool _isPageFinished = false;
  double _progress = 0.0;
  String? _lastError;

  void Function(ExtractedQrisPayload payload)? _onExtracted;
  VoidCallback? _onPaymentFinishedUrl;
  void Function(double progress)? _onProgress;
  void Function(bool isLoading)? _onPageLoadingChanged;
  VoidCallback? _onPageFinished;

  WebViewController? get webViewController => _controller;
  bool get isDisposed => _disposed;
  bool get isResolvedDirectQr => _resolvedDirectQr;
  bool get isLoading => _isLoading;
  bool get isPageFinished => _isPageFinished;
  double get progress => _progress;
  String? get lastError => _lastError;

  /// Mengganti callback aktif (berguna saat controller dipindah dari dialog preload ke layar QRIS).
  void setCallbacks({
    required void Function(ExtractedQrisPayload payload) onExtracted,
    required VoidCallback onPaymentFinishedUrl,
    void Function(double progress)? onProgress,
    void Function(bool isLoading)? onPageLoadingChanged,
    VoidCallback? onPageFinished,
  }) {
    _onExtracted = onExtracted;
    _onPaymentFinishedUrl = onPaymentFinishedUrl;
    _onProgress = onProgress;
    _onPageLoadingChanged = onPageLoadingChanged;
    _onPageFinished = onPageFinished;
  }

  static const String _extractorJs = r'''
(function() {
  try {
    if (window.__ksppsQrResolved) return;
    var emvRegex = /000201[^\x00-\x1F"<>\\]{28,}6304[0-9A-Fa-f]{4}/;

    function unescapeText(s) {
      return String(s || '')
        .replace(/\\\//g, '/')
        .replace(/\\u002f/gi, '/')
        .replace(/\\u0026/gi, '&')
        .replace(/\\u003d/gi, '=')
        .replace(/\\"/g, '"');
    }

    function sendBridge(type, value) {
      if (!value || !window.KsppsQrisBridge) return false;
      try {
        window.KsppsQrisBridge.postMessage(JSON.stringify({ type: type, value: String(value) }));
        if (type === 'emv' || type === 'image') {
          window.__ksppsQrResolved = true;
        }
        return true;
      } catch (e) {
        return false;
      }
    }

    function scanTextForEmv(txt) {
      if (!txt || typeof txt !== 'string') return false;
      var normalized = unescapeText(txt);
      var m = normalized.match(emvRegex);
      if (m && m[0]) {
        return sendBridge('emv', m[0]);
      }
      return false;
    }

    function scanObjectForQr(obj, depth) {
      if (!obj || typeof obj !== 'object' || depth > 6) return false;
      var qrKeys = ['qr_string', 'qrstring', 'qr_content', 'qrcontent', 'qr_code', 'qrcode', 'qris', 'qris_string', 'emv'];
      var urlKeys = ['qr_url', 'qrurl', 'qr_image', 'qrimage', 'image_url', 'imageurl'];

      if (Array.isArray(obj)) {
        for (var a = 0; a < obj.length; a++) {
          if (scanObjectForQr(obj[a], depth + 1)) return true;
        }
        return false;
      }

      var keys = Object.keys(obj);
      for (var i = 0; i < keys.length; i++) {
        var k = keys[i];
        var lk = k.toLowerCase();
        var v = obj[k];

        if (typeof v === 'string') {
          if (v.indexOf('000201') !== -1 && scanTextForEmv(v)) return true;
          if (v.indexOf('data:image/') === 0 && v.length > 200) {
            return sendBridge('image', v);
          }
          if (qrKeys.indexOf(lk) !== -1 && (v.indexOf('iVBORw0') === 0 || v.indexOf('/9j/') === 0)) {
            return sendBridge('image', 'data:image/png;base64,' + v);
          }
          if (urlKeys.indexOf(lk) !== -1 && v.indexOf('http') === 0) {
            return sendBridge('image_url', v);
          }
        } else if (v && typeof v === 'object') {
          if (scanObjectForQr(v, depth + 1)) return true;
        }
      }
      return false;
    }

    function inspectNetworkBody(body) {
      if (!body || typeof body !== 'string') return;
      if (scanTextForEmv(body)) return;
      try {
        var trimmed = body.trim();
        if (trimmed.charAt(0) === '{' || trimmed.charAt(0) === '[') {
          var parsed = JSON.parse(trimmed);
          scanObjectForQr(parsed, 0);
        }
      } catch (e) {}
    }

    // 1. Hook fetch & XHR sekali saja untuk menangkap respon API QRIS dari DOKU Checkout
    if (!window.__ksppsHookedNetwork) {
      window.__ksppsHookedNetwork = true;
      var origFetch = window.fetch;
      if (origFetch) {
        window.fetch = function() {
          return origFetch.apply(this, arguments).then(function(res) {
            try {
              res.clone().text().then(inspectNetworkBody).catch(function() {});
            } catch (e) {}
            return res;
          });
        };
      }

      var origSend = XMLHttpRequest.prototype.send;
      XMLHttpRequest.prototype.send = function() {
        this.addEventListener('load', function() {
          try {
            if (typeof this.responseText === 'string') {
              inspectNetworkBody(this.responseText);
            }
          } catch (e) {}
        });
        return origSend.apply(this, arguments);
      };
    }

    function tryClickQrisTrigger(doc) {
      var now = Date.now();
      var count = doc.__ksppsAutoClickCount || 0;
      var lastAt = doc.__ksppsLastClickAt || 0;
      if (count >= 5 || (now - lastAt) < 1200) return;

      var candidates = doc.querySelectorAll('button, [role="button"], label, a, [tabindex], div, span');
      for (var n = 0; n < candidates.length; n++) {
        var node = candidates[n];
        if (!node || node.offsetParent === null) continue;
        var label = (node.innerText || node.getAttribute('aria-label') || '').replace(/\s+/g, ' ').trim();
        if (!label || label.length > 48) continue;
        if (/^(qris(\s+nasional|\s+payment|\s+code)?|bayar\s+dengan\s+qris|pay\s+with\s+qris|tampilkan\s+qr(\s*code|\s*ris)?|generate\s+qr(is)?|show\s+qr)$/i.test(label)) {
          var target = node.closest ? (node.closest('button, [role="button"], a, label, [tabindex]') || node) : node;
          doc.__ksppsAutoClickCount = count + 1;
          doc.__ksppsLastClickAt = now;
          try { target.click(); } catch (e) {}
          break;
        }
      }
    }

    function fetchBlobAsDataUrl(src) {
      if (!src || window.__ksppsFetchedBlobSrc === src) return;
      window.__ksppsFetchedBlobSrc = src;
      try {
        fetch(src).then(function(r) {
          if (!r.ok) return null;
          return r.blob();
        }).then(function(blob) {
          if (!blob || blob.size < 80) return;
          var reader = new FileReader();
          reader.onloadend = function() {
            if (typeof reader.result === 'string' && reader.result.indexOf('data:image/') === 0) {
              sendBridge('image', reader.result);
            }
          };
          reader.readAsDataURL(blob);
        }).catch(function() {});
      } catch (e) {}
    }

    function scanDocument(doc) {
      if (!doc) return false;
      try {
        var rawText = doc.body ? doc.body.innerText : '';
        if (scanTextForEmv(rawText)) return true;

        var scripts = doc.querySelectorAll('script, [data-qr], [data-qris], input[type="hidden"]');
        for (var s = 0; s < scripts.length; s++) {
          var el = scripts[s];
          var candidate = el.getAttribute('data-qr') || el.getAttribute('data-qris') || el.value || el.textContent || '';
          if (scanTextForEmv(candidate)) return true;
        }

        // Ekstrak <canvas> QRIS (validasi ada piksel gelap + terang agar bukan canvas kosong)
        var canvases = doc.querySelectorAll('canvas');
        for (var c = 0; c < canvases.length; c++) {
          var cv = canvases[c];
          if (cv.width < 90 || cv.height < 90 || Math.abs(cv.width - cv.height) > 60) continue;
          try {
            var ctx = cv.getContext('2d');
            if (ctx) {
              var imgData = ctx.getImageData(0, 0, cv.width, cv.height).data;
              var hasDark = false;
              var hasLight = false;
              var step = Math.max(4, Math.floor(imgData.length / 400)) * 4;
              for (var p = 0; p < imgData.length; p += step) {
                if (imgData[p + 3] > 128) {
                  var lum = imgData[p] + imgData[p + 1] + imgData[p + 2];
                  if (lum < 350) hasDark = true;
                  if (lum > 600) hasLight = true;
                  if (hasDark && hasLight) break;
                }
              }
              if (!hasDark || !hasLight) continue;
            }
            var dataUrl = cv.toDataURL('image/png');
            if (dataUrl && dataUrl.length > 500) {
              if (sendBridge('image', dataUrl)) return true;
            }
          } catch (e) {}
        }

        // Ekstrak <svg> QRIS (React/Vue QRCodeSVG) menjadi gambar PNG resolusi tinggi
        var svgs = doc.querySelectorAll('svg');
        for (var g = 0; g < svgs.length; g++) {
          var svg = svgs[g];
          if (svg.__ksppsExported) continue;
          var srect = svg.getBoundingClientRect();
          if (srect.width < 90 || srect.height < 90 || Math.abs(srect.width - srect.height) > 60) continue;
          var shapes = svg.querySelectorAll('path, rect, polygon');
          var firstD = shapes.length > 0 ? (shapes[0].getAttribute('d') || '') : '';
          if (shapes.length < 10 && firstD.length < 180) continue;

          svg.__ksppsExported = true;
          try {
            var clone = svg.cloneNode(true);
            clone.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
            clone.setAttribute('width', '420');
            clone.setAttribute('height', '420');
            if (!clone.getAttribute('viewBox')) {
              clone.setAttribute('viewBox', '0 0 ' + Math.round(srect.width) + ' ' + Math.round(srect.height));
            }
            var bg = doc.createElementNS('http://www.w3.org/2000/svg', 'rect');
            bg.setAttribute('width', '100%');
            bg.setAttribute('height', '100%');
            bg.setAttribute('fill', '#ffffff');
            clone.insertBefore(bg, clone.firstChild);

            var xml = new XMLSerializer().serializeToString(clone);
            var svgImg = new Image();
            var svgUrl = URL.createObjectURL(new Blob([xml], { type: 'image/svg+xml;charset=utf-8' }));
            svgImg.onload = function() {
              try {
                var off = doc.createElement('canvas');
                off.width = 420;
                off.height = 420;
                var octx = off.getContext('2d');
                octx.fillStyle = '#ffffff';
                octx.fillRect(0, 0, 420, 420);
                octx.drawImage(svgImg, 0, 0, 420, 420);
                URL.revokeObjectURL(svgUrl);
                var pngOut = off.toDataURL('image/png');
                if (pngOut && pngOut.length > 500) {
                  sendBridge('image', pngOut);
                }
              } catch (ex) {}
            };
            svgImg.src = svgUrl;
          } catch (e) {}
        }

        // Ekstrak <img> QRIS (data URI, canvas readback, blob fetch, atau URL HTTP terproteksi CORS)
        var imgs = doc.querySelectorAll('img');
        for (var i = 0; i < imgs.length; i++) {
          var img = imgs[i];
          var src = img.getAttribute('src') || img.currentSrc || '';
          if (!src) continue;

          var meta = ((img.alt || '') + ' ' + (img.id || '') + ' ' + (img.className || '') + ' ' + src).toLowerCase();
          var isUiAsset = (meta.indexOf('logo') !== -1 || meta.indexOf('icon') !== -1 || meta.indexOf('avatar') !== -1 || meta.indexOf('badge') !== -1) && meta.indexOf('qr') === -1;
          if (isUiAsset) continue;

          var nw = img.naturalWidth || img.width || 0;
          var nh = img.naturalHeight || img.height || 0;
          if (nw < 90 || nh < 90 || Math.abs(nw - nh) > 60) continue;

          if (src.indexOf('data:image/') === 0) {
            if (sendBridge('image', src)) return true;
          }

          try {
            if (img.complete && img.naturalWidth >= 90) {
              var offImg = doc.createElement('canvas');
              offImg.width = img.naturalWidth;
              offImg.height = img.naturalHeight;
              offImg.getContext('2d').drawImage(img, 0, 0);
              var exported = offImg.toDataURL('image/png');
              if (exported && exported.length > 500) {
                if (sendBridge('image', exported)) return true;
              }
            }
          } catch (corsErr) {}

          if (src.indexOf('blob:') === 0) {
            fetchBlobAsDataUrl(src);
          } else if (src.indexOf('http') === 0) {
            fetchBlobAsDataUrl(src);
            sendBridge('image_url', src);
            return false;
          }
        }

        // Cek background-image CSS pada kontainer QRIS
        var qrContainers = doc.querySelectorAll('[class*="qr"], [id*="qr"]');
        for (var q = 0; q < qrContainers.length; q++) {
          var qel = qrContainers[q];
          var bgImg = window.getComputedStyle ? window.getComputedStyle(qel).backgroundImage : '';
          if (bgImg && bgImg.indexOf('url(') === 0) {
            var mUrl = bgImg.match(/url\(["']?([^"')]+)["']?\)/);
            if (mUrl && mUrl[1]) {
              if (mUrl[1].indexOf('data:image/') === 0 && sendBridge('image', mUrl[1])) return true;
              if (mUrl[1].indexOf('http') === 0) sendBridge('image_url', mUrl[1]);
            }
          }
        }

        // Bila QR belum muncul di DOM, coba klik tombol / tab QRIS di DOKU Checkout
        tryClickQrisTrigger(doc);
      } catch (e) {}
      return false;
    }

    try {
      if (window.localStorage) {
        var qrisStorage = window.localStorage.getItem('qris_data');
        if (qrisStorage) inspectNetworkBody(qrisStorage);
      }
    } catch (e) {}

    if (scanDocument(document)) return;

    var frames = document.querySelectorAll('iframe');
    for (var f = 0; f < frames.length; f++) {
      try {
        var fdoc = frames[f].contentDocument;
        if (fdoc && scanDocument(fdoc)) return;
      } catch (e) {}
    }
  } catch (err) {}
})();
''';

  /// Memulai pemuatan halaman DOKU Checkout di `WebViewController`.
  /// Mengembalikan `true` jika platform mendukung WebView, `false` jika di test/web atau gagal.
  bool start({
    required String url,
    required void Function(ExtractedQrisPayload payload) onExtracted,
    required VoidCallback onPaymentFinishedUrl,
    void Function(double progress)? onProgress,
    void Function(bool isLoading)? onPageLoadingChanged,
    VoidCallback? onPageFinished,
  }) {
    setCallbacks(
      onExtracted: onExtracted,
      onPaymentFinishedUrl: onPaymentFinishedUrl,
      onProgress: onProgress,
      onPageLoadingChanged: onPageLoadingChanged,
      onPageFinished: onPageFinished,
    );

    if (kIsWeb || url.trim().isEmpty) {
      _lastError = 'URL pembayaran DOKU kosong.';
      return false;
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      _lastError = 'Format URL pembayaran DOKU tidak valid.';
      return false;
    }

    try {
      _lastError = null;
      _isLoading = true;
      _isPageFinished = false;
      _progress = 0.0;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..addJavaScriptChannel(
          'KsppsQrisBridge',
          onMessageReceived: (JavaScriptMessage message) {
            if (_disposed || _resolvedDirectQr) return;
            final payload = DokuQrPayloadParser.parseBridgeMessage(message.message);
            if (payload != null && payload.isValid) {
              if (payload.hasQrString || payload.hasImageBytes) {
                _resolvedDirectQr = true;
                _domPollTimer?.cancel();
              }
              _onExtracted?.call(payload);
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (!_disposed) {
                _progress = progress / 100.0;
                _onProgress?.call(_progress);
              }
            },
            onPageStarted: (currentUrl) {
              if (_disposed) return;
              _isLoading = true;
              _onPageLoadingChanged?.call(true);
              if (DokuQrPayloadParser.isDokuFinishUrl(currentUrl)) {
                _onPaymentFinishedUrl?.call();
              }
              _runScanOnce();
            },
            onPageFinished: (currentUrl) {
              if (_disposed) return;
              _isLoading = false;
              _isPageFinished = true;
              _onPageLoadingChanged?.call(false);
              _onPageFinished?.call();
              if (DokuQrPayloadParser.isDokuFinishUrl(currentUrl)) {
                _onPaymentFinishedUrl?.call();
              }
              _runScanOnce();
              _ensureDomPolling();
            },
            onWebResourceError: (err) {
              if (!_disposed) {
                if (err.isForMainFrame == true) {
                  _lastError = err.description;
                }
                _isLoading = false;
                _onPageLoadingChanged?.call(false);
              }
            },
            onNavigationRequest: (request) async {
              final navUrl = request.url;
              final navUri = Uri.tryParse(navUrl);
              if (navUri != null &&
                  navUri.scheme != 'http' &&
                  navUri.scheme != 'https' &&
                  navUri.scheme != 'about' &&
                  navUri.scheme != 'data' &&
                  navUri.scheme != 'blob') {
                try {
                  if (await canLaunchUrl(navUri)) {
                    await launchUrl(navUri, mode: LaunchMode.externalApplication);
                    return NavigationDecision.prevent;
                  }
                } catch (_) {}
              }
              if (DokuQrPayloadParser.isDokuFinishUrl(navUrl)) {
                _onPaymentFinishedUrl?.call();
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(uri);

      _controller = controller;
      _ensureDomPolling();
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  void _ensureDomPolling() {
    if (_disposed || _resolvedDirectQr || _domPollTimer != null) return;
    _domPollTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_disposed || _resolvedDirectQr || _domPollCount >= 55) {
        timer.cancel();
        _domPollTimer = null;
        return;
      }
      _domPollCount++;
      _runScanOnce();
    });
  }

  void _runScanOnce() {
    final c = _controller;
    if (c == null || _disposed || _resolvedDirectQr) return;
    c.runJavaScript(_extractorJs).catchError((_) {});
  }

  void reload() {
    if (_disposed) return;
    _resolvedDirectQr = false;
    _isPageFinished = false;
    _isLoading = true;
    _lastError = null;
    _domPollCount = 0;
    _controller?.reload().catchError((_) {});
    _ensureDomPolling();
  }

  void dispose() {
    _disposed = true;
    _domPollTimer?.cancel();
    _domPollTimer = null;
    _onExtracted = null;
    _onPaymentFinishedUrl = null;
    _onProgress = null;
    _onPageLoadingChanged = null;
    _onPageFinished = null;
    _controller = null;
  }
}

/// Widget WebView QRIS DOKU tersemat langsung di dalam halaman Pembayaran QRIS aplikasi.
class InlineDokuQrisWebView extends StatelessWidget {
  final WebViewController controller;
  final bool isLoading;
  final double progress;
  final Color accentColor;
  final VoidCallback onReload;

  const InlineDokuQrisWebView({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.progress,
    required this.accentColor,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Icon(Icons.qr_code_2_rounded, size: 16, color: accentColor),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Kode Pembayaran QRIS Resmi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onReload,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 15, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Muat Ulang',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading && progress < 1.0)
            LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              minHeight: 2.5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          SizedBox(
            height: 460,
            width: double.infinity,
            child: WebViewWidget(
              key: ValueKey('inline_doku_qris_${identityHashCode(controller)}'),
              controller: controller,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
            ),
          ),
        ],
      ),
    );
  }
}
