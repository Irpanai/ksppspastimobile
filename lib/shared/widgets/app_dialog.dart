import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Unified modern dialog system for KSPPS PASTI mobile app.
/// Ensures all alerts, errors, warnings, info notices, and confirmations are
/// centered, beautifully styled, and cohesive.
class AppDialog {
  /// Show centered modern Error Dialog
  static Future<T?> showError<T>(
    BuildContext context, {
    String title = 'Terjadi Kesalahan',
    required String message,
    String buttonText = 'Mengerti',
    VoidCallback? onConfirm,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
  }) {
    // User request: Jangan munculkan pesan error timeout
    if (message.trim().isEmpty || message.toLowerCase().contains('timeout')) {
      return Future.value(null);
    }
    return _showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogContent(
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBgColor: const Color(0xFFFEE2E2),
        iconBorderColor: const Color(0xFFFECACA),
        title: title,
        message: message,
        primaryButtonText: buttonText,
        primaryButtonColor: const Color(0xFFDC2626),
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: () {
          final nav = Navigator.maybeOf(context, rootNavigator: true);
          if (nav != null && nav.canPop()) nav.pop();
          if (onConfirm != null) onConfirm();
        },
        onSecondaryPressed: secondaryButtonText != null
            ? () {
                final nav = Navigator.maybeOf(context, rootNavigator: true);
                if (nav != null && nav.canPop()) nav.pop();
                if (onSecondaryPressed != null) onSecondaryPressed();
              }
            : null,
      ),
    );
  }

  /// Show centered modern Warning Dialog
  static Future<T?> showWarning<T>(
    BuildContext context, {
    String title = 'Perhatian',
    required String message,
    String buttonText = 'Mengerti',
    VoidCallback? onConfirm,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
  }) {
    if (message.trim().isEmpty || message.toLowerCase().contains('timeout')) {
      return Future.value(null);
    }
    return _showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogContent(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFD97706),
        iconBgColor: const Color(0xFFFEF3C7),
        iconBorderColor: const Color(0xFFFDE68A),
        title: title,
        message: message,
        primaryButtonText: buttonText,
        primaryButtonColor: const Color(0xFFD97706),
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: () {
          final nav = Navigator.maybeOf(context, rootNavigator: true);
          if (nav != null && nav.canPop()) nav.pop();
          if (onConfirm != null) onConfirm();
        },
        onSecondaryPressed: secondaryButtonText != null
            ? () {
                final nav = Navigator.maybeOf(context, rootNavigator: true);
                if (nav != null && nav.canPop()) nav.pop();
                if (onSecondaryPressed != null) onSecondaryPressed();
              }
            : null,
      ),
    );
  }

  /// Show centered modern Info Dialog
  static Future<T?> showInfo<T>(
    BuildContext context, {
    String title = 'Informasi',
    required String message,
    String buttonText = 'Mengerti',
    Widget? customContent,
    VoidCallback? onConfirm,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    IconData icon = Icons.info_outline_rounded,
    Color primaryColor = const Color(0xFF0E7955),
    bool barrierDismissible = true,
  }) {
    if (message.trim().isEmpty) {
      return Future.value(null);
    }
    return _showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogContent(
        icon: icon,
        iconColor: const Color(0xFF0284C7),
        iconBgColor: const Color(0xFFE0F2FE),
        iconBorderColor: const Color(0xFFBAE6FD),
        title: title,
        message: message,
        customContent: customContent,
        primaryButtonText: buttonText,
        primaryButtonColor: primaryColor,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: () {
          final nav = Navigator.maybeOf(context, rootNavigator: true);
          if (nav != null && nav.canPop()) nav.pop();
          if (onConfirm != null) onConfirm();
        },
        onSecondaryPressed: secondaryButtonText != null
            ? () {
                final nav = Navigator.maybeOf(context, rootNavigator: true);
                if (nav != null && nav.canPop()) nav.pop();
                if (onSecondaryPressed != null) onSecondaryPressed();
              }
            : null,
      ),
    );
  }

  /// Show centered modern Success Dialog
  static Future<T?> showSuccess<T>(
    BuildContext context, {
    String title = 'Berhasil!',
    required String message,
    String buttonText = 'Lanjutkan',
    Widget? customContent,
    VoidCallback? onConfirm,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = false,
  }) {
    return _showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogContent(
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF16A34A),
        iconBgColor: const Color(0xFFDCFCE7),
        iconBorderColor: const Color(0xFFA7F3D0),
        title: title,
        message: message,
        customContent: customContent,
        primaryButtonText: buttonText,
        primaryButtonColor: const Color(0xFF16A34A),
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: () {
          final nav = Navigator.maybeOf(context, rootNavigator: true);
          if (nav != null && nav.canPop()) nav.pop();
          if (onConfirm != null) onConfirm();
        },
        onSecondaryPressed: secondaryButtonText != null
            ? () {
                final nav = Navigator.maybeOf(context, rootNavigator: true);
                if (nav != null && nav.canPop()) nav.pop();
                if (onSecondaryPressed != null) onSecondaryPressed();
              }
            : null,
      ),
    );
  }

  /// Show centered modern Coming Soon / Info Dialog
  static Future<T?> showComingSoon<T>(
    BuildContext context, {
    String title = 'Segera Hadir',
    String featureName = 'Layanan Rahn (Gadai Syariah)',
    String? message,
    String buttonText = 'Mengerti',
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    final displayMessage = message ??
        'Fitur $featureName saat ini sedang dalam tahap pengembangan dan integrasi sistem. Nantikan kemudahan layanan ini dalam waktu dekat!';

    return _showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogContent(
        icon: Icons.hourglass_top_rounded,
        iconColor: const Color(0xFFD97706),
        iconBgColor: const Color(0xFFFEF3C7),
        iconBorderColor: const Color(0xFFFDE68A),
        title: title,
        message: displayMessage,
        customContent: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.handshake_outlined, size: 16, color: Color(0xFF047857)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  featureName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        ),
        primaryButtonText: buttonText,
        primaryButtonColor: const Color(0xFF047857),
        onPrimaryPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          if (onConfirm != null) onConfirm();
        },
      ),
    );
  }

  /// Show centered modern Confirmation Dialog
  /// Returns bool: true if user confirms, false if cancelled.
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Ya, Lanjutkan',
    String cancelText = 'Batal',
    bool isDestructive = false,
    IconData? icon,
    Color? iconColor,
    Color? iconBgColor,
    Widget? customContent,
    bool barrierDismissible = true,
  }) async {
    final result = await _showAnimatedDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogContent(
        icon: icon ?? (isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded),
        iconColor: iconColor ?? (isDestructive ? const Color(0xFFDC2626) : const Color(0xFF388E3C)),
        iconBgColor: iconBgColor ?? (isDestructive ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7)),
        iconBorderColor: isDestructive ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
        title: title,
        message: message,
        customContent: customContent,
        primaryButtonText: confirmText,
        primaryButtonColor: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF388E3C),
        secondaryButtonText: cancelText,
        onPrimaryPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        onSecondaryPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
      ),
    );
    return result ?? false;
  }

  /// Show a cohesive custom dialog wrapped in the same unified animation & card shell.
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color iconBorderColor,
    required String title,
    required String message,
    Widget? customContent,
    required String primaryButtonText,
    required Color primaryButtonColor,
    required VoidCallback onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
  }) {
    return _showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogContent(
        icon: icon,
        iconColor: iconColor,
        iconBgColor: iconBgColor,
        iconBorderColor: iconBorderColor,
        title: title,
        message: message,
        customContent: customContent,
        primaryButtonText: primaryButtonText,
        primaryButtonColor: primaryButtonColor,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
      ),
    );
  }

  /// Expose animated loading / custom card dialog shell so non-standard modals
  /// match AppDialog proportions, radius, white card surface, and backdrop blur.
  static Future<T?> showShell<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = false,
  }) {
    return _showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogCardShell(child: child),
    );
  }

  /// Subtle floating pill above modal sheets (useful for copy-to-clipboard).
  static void showFloatingToast(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle_rounded,
    Color backgroundColor = const Color(0xFF16A34A),
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 24,
        right: 24,
        bottom: 32 + MediaQuery.of(ctx).padding.bottom,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Timer(duration, () {
      if (entry.mounted) entry.remove();
    });
  }

  /// Internal animated dialog launcher with backdrop blur and scale transition
  static Future<T?> _showAnimatedDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, _) {
        final curveValue = Curves.easeOutBack.transform(anim1.value);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 3 * anim1.value,
            sigmaY: 3 * anim1.value,
          ),
          child: Transform.scale(
            scale: (0.85 + (curveValue * 0.15)).clamp(0.0, 1.05),
            child: Opacity(
              opacity: anim1.value.clamp(0.0, 1.0),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppDialogCardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _AppDialogCardShell({
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: 350,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: child,
      ),
    );
  }
}

class _AppDialogContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color iconBorderColor;
  final String title;
  final String message;
  final Widget? customContent;
  final String primaryButtonText;
  final Color primaryButtonColor;
  final String? secondaryButtonText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;

  const _AppDialogContent({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.iconBorderColor,
    required this.title,
    required this.message,
    this.customContent,
    required this.primaryButtonText,
    required this.primaryButtonColor,
    this.secondaryButtonText,
    required this.onPrimaryPressed,
    this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _AppDialogCardShell(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            // Centered Icon Badge
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
                border: Border.all(color: iconBorderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 34),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),

            // Custom Content if any
            if (customContent != null) ...[
              const SizedBox(height: 16),
              customContent!,
            ],

            const SizedBox(height: 24),

            // Actions
            if (secondaryButtonText != null)
              Row(
                children: [
                  // Secondary / Cancel Button
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: onSecondaryPressed,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                          backgroundColor: const Color(0xFFF8FAFC),
                          foregroundColor: const Color(0xFF475569),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: Text(
                          secondaryButtonText!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Primary / Confirm Button
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: onPrimaryPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryButtonColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: Text(
                          primaryButtonText,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // Single Action Button (Full Width)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: onPrimaryPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryButtonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    primaryButtonText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
    );
  }
}
