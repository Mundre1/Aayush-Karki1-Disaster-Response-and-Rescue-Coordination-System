import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/app_config.dart';

/// Logging interceptor for Dio to log all requests and responses
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timestamp = DateTime.now().toIso8601String();
    final method = options.method.toUpperCase();
    final uri = options.uri.toString();

    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📤 API REQUEST [$timestamp]');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('Method: $method');
    debugPrint('URL: $uri');

    // Log headers (excluding sensitive data)
    if (options.headers.isNotEmpty) {
      debugPrint('Headers:');
      options.headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization') {
          debugPrint('  $key: Bearer [HIDDEN]');
        } else {
          debugPrint('  $key: $value');
        }
      });
    }

    // Log query parameters
    if (options.queryParameters.isNotEmpty) {
      debugPrint('Query Parameters:');
      options.queryParameters.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }

    // Log request body
    if (options.data != null) {
      debugPrint('Request Body:');
      if (options.data is FormData) {
        // Handle FormData (multipart)
        final formData = options.data as FormData;
        debugPrint('  Type: multipart/form-data');
        for (var field in formData.fields) {
          debugPrint('  ${field.key}: ${field.value}');
        }
        if (formData.files.isNotEmpty) {
          for (var file in formData.files) {
            debugPrint(
              '  File: ${file.key} - ${file.value.filename} (${file.value.length} bytes)',
            );
          }
        }
      } else {
        // Pretty print JSON
        try {
          final jsonString = const JsonEncoder.withIndent(
            '  ',
          ).convert(options.data);
          debugPrint(jsonString);
        } catch (e) {
          debugPrint('  ${options.data}');
        }
      }
    }

    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('');

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final timestamp = DateTime.now().toIso8601String();
    final method = response.requestOptions.method.toUpperCase();
    final uri = response.requestOptions.uri.toString();
    final statusCode = response.statusCode;
    final statusMessage = response.statusMessage ?? 'N/A';

    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📥 API RESPONSE [$timestamp]');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('Method: $method');
    debugPrint('URL: $uri');
    debugPrint('Status Code: $statusCode $statusMessage');

    // Log response headers
    if (response.headers.map.isNotEmpty) {
      debugPrint('Response Headers:');
      response.headers.map.forEach((key, values) {
        debugPrint('  $key: ${values.join(", ")}');
      });
    }

    // Log response data
    if (response.data != null) {
      debugPrint('Response Body:');
      try {
        // Try to pretty print JSON
        if (response.data is String) {
          final jsonData = jsonDecode(response.data as String);
          final jsonString = const JsonEncoder.withIndent(
            '  ',
          ).convert(jsonData);
          debugPrint(jsonString);
        } else if (response.data is Map || response.data is List) {
          final jsonString = const JsonEncoder.withIndent(
            '  ',
          ).convert(response.data);
          debugPrint(jsonString);
        } else {
          debugPrint('  ${response.data}');
        }
      } catch (e) {
        // If not JSON, print as is
        debugPrint('  ${response.data}');
      }
    }

    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('');

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final timestamp = DateTime.now().toIso8601String();
    final method = err.requestOptions.method.toUpperCase();
    final uri = err.requestOptions.uri.toString();

    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('❌ API ERROR [$timestamp]');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('Method: $method');
    debugPrint('URL: $uri');
    debugPrint('Error Type: ${err.type}');
    debugPrint('Error Message: ${err.message}');

    if (err.response != null) {
      debugPrint('Status Code: ${err.response?.statusCode}');
      debugPrint('Status Message: ${err.response?.statusMessage ?? "N/A"}');

      if (err.response?.data != null) {
        debugPrint('Error Response Body:');
        try {
          if (err.response?.data is String) {
            final jsonData = jsonDecode(err.response!.data as String);
            final jsonString = const JsonEncoder.withIndent(
              '  ',
            ).convert(jsonData);
            debugPrint(jsonString);
          } else if (err.response?.data is Map || err.response?.data is List) {
            final jsonString = const JsonEncoder.withIndent(
              '  ',
            ).convert(err.response!.data);
            debugPrint(jsonString);
          } else {
            debugPrint('  ${err.response?.data}');
          }
        } catch (e) {
          debugPrint('  ${err.response?.data}');
        }
      }
    } else {
      debugPrint('No response received from server');
    }

    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('');

    super.onError(err, handler);
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  String? _token;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add logging interceptor first
    _dio.interceptors.add(LoggingInterceptor());

    // Add interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle errors globally if needed
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConfig.tokenKey);
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Options? options,
  }) async {
    try {
      return await _dio.post(endpoint, data: body, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Options? options,
  }) async {
    try {
      return await _dio.put(endpoint, data: body, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Options? options,
  }) async {
    try {
      return await _dio.patch(endpoint, data: body, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String endpoint, {Options? options}) async {
    try {
      return await _dio.delete(endpoint, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> postMultipart(
    String endpoint,
    Map<String, String> fields,
    String fileField,
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      final formData = FormData.fromMap({
        ...fields,
        fileField: MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      return await _dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> postMultipartFromFile(
    String endpoint,
    Map<String, String> fields,
    String fileField,
    String filePath,
  ) async {
    try {
      final formData = FormData.fromMap({
        ...fields,
        fileField: await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      return await _dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> putMultipart(
    String endpoint,
    Map<String, String> fields, {
    String? fileField,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      final data = <String, dynamic>{...fields};
      if (fileField != null && fileBytes != null && fileName != null) {
        data[fileField] = MultipartFile.fromBytes(fileBytes, filename: fileName);
      }
      final formData = FormData.fromMap(data);

      return await _dio.put(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> putMultipartFromFile(
    String endpoint,
    Map<String, String> fields, {
    String? fileField,
    String? filePath,
  }) async {
    try {
      final data = <String, dynamic>{...fields};
      if (fileField != null && filePath != null) {
        data[fileField] = await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        );
      }
      final formData = FormData.fromMap(data);

      return await _dio.put(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      // Server responded with error
      return Exception(
        error.response?.data['message'] ??
            'Server error: ${error.response?.statusCode}',
      );
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout. Please check your internet.');
    } else if (error.type == DioExceptionType.connectionError) {
      return Exception('No internet connection.');
    } else {
      return Exception('An error occurred: ${error.message}');
    }
  }
}
