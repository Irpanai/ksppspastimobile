import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import 'api_response.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;
  final bool isTimeout;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
    this.isTimeout = false,
  });

  @override
  String toString() => message;
}

class ApiClient {
  static final http.Client _client = http.Client();

  static Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '${ApiConstants.baseUrl}$cleanEndpoint';
    
    if (queryParams != null && queryParams.isNotEmpty) {
      final filteredParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null) {
          filteredParams[key] = value.toString();
        }
      });
      return Uri.parse(fullUrl).replace(queryParameters: filteredParams);
    }
    
    return Uri.parse(fullUrl);
  }

  static Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool withAuth = true,
    T Function(dynamic json)? fromJsonT,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final headers = await _getHeaders(withAuth: withAuth);

      final response = await _client.get(uri, headers: headers).timeout(
        timeout ?? const Duration(seconds: 30),
      );

      return _processResponse<T>(response, fromJsonT);
    } on SocketException {
      throw ApiException(message: 'Tidak dapat terhubung ke server. Pastikan backend aktif.');
    } on http.ClientException {
      throw ApiException(message: 'Gagal menghubungi server. Periksa koneksi jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  static Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    bool withAuth = true,
    T Function(dynamic json)? fromJsonT,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _getHeaders(withAuth: withAuth);
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .post(uri, headers: headers, body: encodedBody)
          .timeout(timeout ?? const Duration(seconds: 30));

      return _processResponse<T>(response, fromJsonT);
    } on SocketException {
      throw ApiException(message: 'Tidak dapat terhubung ke server backend.');
    } on http.ClientException {
      throw ApiException(message: 'Gagal menghubungi server. Periksa koneksi jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  static Future<ApiResponse<T>> postMultipart<T>(
    String endpoint, {
    File? file,
    List<int>? fileBytes,
    String? filename,
    required String fileField,
    Map<String, String>? fields,
    bool withAuth = true,
    T Function(dynamic json)? fromJsonT,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _getHeaders(withAuth: withAuth);
      // Remove Content-Type so MultipartRequest sets multipart/form-data with proper boundary
      headers.remove('Content-Type');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            fileBytes,
            filename: filename ?? 'photo.jpg',
          ),
        );
      } else if (file != null) {
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              fileField,
              bytes,
              filename: filename ?? 'photo.jpg',
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              fileField,
              file.path,
              filename: filename,
            ),
          );
        }
      }

      final streamedResponse = await _client.send(request).timeout(
            timeout ?? const Duration(seconds: 30),
          );
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse<T>(response, fromJsonT);
    } on SocketException {
      throw ApiException(message: 'Tidak dapat terhubung ke server backend.');
    } on http.ClientException {
      throw ApiException(message: 'Gagal menghubungi server. Periksa koneksi jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  static Future<ApiResponse<T>> postMultipartFiles<T>(
    String endpoint, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
    bool withAuth = true,
    T Function(dynamic json)? fromJsonT,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _getHeaders(withAuth: withAuth);
      // Remove Content-Type so MultipartRequest sets multipart/form-data with proper boundary
      headers.remove('Content-Type');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.addAll(files);

      final streamedResponse = await _client.send(request).timeout(
            timeout ?? const Duration(seconds: 30),
          );
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse<T>(response, fromJsonT);
    } on SocketException {
      throw ApiException(message: 'Tidak dapat terhubung ke server backend.');
    } on http.ClientException {
      throw ApiException(message: 'Gagal menghubungi server. Periksa koneksi jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  static Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    bool withAuth = true,
    T Function(dynamic json)? fromJsonT,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _getHeaders(withAuth: withAuth);
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .put(uri, headers: headers, body: encodedBody)
          .timeout(timeout ?? const Duration(seconds: 30));

      return _processResponse<T>(response, fromJsonT);
    } on SocketException {
      throw ApiException(message: 'Tidak dapat terhubung ke server backend.');
    } on http.ClientException {
      throw ApiException(message: 'Gagal menghubungi server. Periksa koneksi jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  static Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic body,
    bool withAuth = true,
    T Function(dynamic json)? fromJsonT,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _getHeaders(withAuth: withAuth);
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .delete(uri, headers: headers, body: encodedBody)
          .timeout(timeout ?? const Duration(seconds: 30));

      return _processResponse<T>(response, fromJsonT);
    } on TimeoutException {
      throw ApiException(message: '', isTimeout: true);
    } on SocketException {
      throw ApiException(message: 'Tidak dapat terhubung ke server backend.');
    } on http.ClientException {
      throw ApiException(message: 'Gagal menghubungi server. Periksa koneksi jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException || e.toString().toLowerCase().contains('timeout')) {
        throw ApiException(message: '', isTimeout: true);
      }
      throw ApiException(message: 'Terjadi kesalahan: ' + e.toString());
    }
  }

  static ApiResponse<T> _processResponse<T>(
    http.Response response,
    T Function(dynamic json)? fromJsonT,
  ) {
    dynamic decodedBody;
    try {
      decodedBody = jsonDecode(response.body);
    } catch (_) {
      decodedBody = null;
    }

    if (decodedBody is Map<String, dynamic>) {
      final apiResponse = ApiResponse<T>.fromJson(decodedBody, fromJsonT);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return apiResponse;
      }

      // Handle Error Responses (400, 401, 403, 404, 422, 500)
      throw ApiException(
        message: apiResponse.errorMessage,
        statusCode: response.statusCode,
        errors: apiResponse.errors,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse<T>(
        success: true,
        message: 'Sukses',
        data: decodedBody as T?,
      );
    } else {
      throw ApiException(
        message: 'Server mengembalikan status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }
}
