import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import 'api_response.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({required this.message, this.statusCode, this.errors});

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
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final headers = await _getHeaders(withAuth: withAuth);

      final response = await _client.get(uri, headers: headers).timeout(
        const Duration(seconds: 15),
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
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _getHeaders(withAuth: withAuth);
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .post(uri, headers: headers, body: encodedBody)
          .timeout(const Duration(seconds: 15));

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
