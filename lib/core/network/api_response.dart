class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic json)? fromJsonT,
  ]) {
    return ApiResponse<T>(
      success: json['success'] is bool ? json['success'] : (json['success'] == 1 || json['success'] == 'true'),
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: json['errors'],
    );
  }

  /// Helper to get a human-readable error string from validation errors or message
  String get errorMessage {
    if (errors != null) {
      if (errors is Map) {
        final Map errMap = errors as Map;
        final List<String> messages = [];
        errMap.forEach((key, value) {
          if (value is List) {
            for (var item in value) {
              if (item != null && item.toString().isNotEmpty) {
                messages.add(item.toString());
              }
            }
          } else if (value is String && value.isNotEmpty && value != 'false' && value != 'true') {
            messages.add(value);
          }
        });
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      } else if (errors is String && (errors as String).isNotEmpty && errors != 'false' && errors != 'true') {
        return errors as String;
      }
    }
    return message.isNotEmpty ? message : 'Terjadi kesalahan pada server.';
  }
}
