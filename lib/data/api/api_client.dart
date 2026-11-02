import 'package:dio/dio.dart';

import '../models/json.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// The one HTTP client the app uses. It attaches the practitioner's access
/// token, refreshes it once on a 401 and retries, and turns every failure
/// into an [ApiException] carrying the backend's own message.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.tokens,
    this.onSessionExpired,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 12),
           receiveTimeout: const Duration(seconds: 20),
           contentType: Headers.jsonContentType,
         ),
       ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final String? token = tokens.accessToken;
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final RequestOptions request = error.requestOptions;
          final bool unauthorised = error.response?.statusCode == 401;
          final bool isAuthCall = request.path.startsWith(
            '/practitioner/auth/',
          );
          if (unauthorised && !isAuthCall && request.extra['retried'] != true) {
            if (await _refresh()) {
              request.extra['retried'] = true;
              try {
                handler.resolve(await _dio.fetch<dynamic>(request));
                return;
              } on DioException catch (retryError) {
                handler.next(retryError);
                return;
              }
            }
            await tokens.clear();
            onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStore tokens;

  /// Called once the session can't be refreshed any more (password changed on
  /// another device, token revoked…) so the app can return to sign-in.
  void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  /// Concurrent 401s share a single refresh call.
  Future<bool> _refresh() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final String? refreshToken = tokens.refreshToken;
    if (refreshToken == null) return false;
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/practitioner/auth/token/refresh',
        data: <String, dynamic>{'refreshToken': refreshToken},
      );
      final Json data =
          ((response.data as Json)['data'] as Map<dynamic, dynamic>)
              .cast<String, dynamic>();
      await tokens.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _unwrap<T>(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? data}) => _unwrap<T>(
    () => _dio.post<dynamic>(path, data: data ?? const <String, dynamic>{}),
  );

  Future<T> put<T>(String path, {Object? data}) => _unwrap<T>(
    () => _dio.put<dynamic>(path, data: data ?? const <String, dynamic>{}),
  );

  Future<T> patch<T>(String path, {Object? data}) => _unwrap<T>(
    () => _dio.patch<dynamic>(path, data: data ?? const <String, dynamic>{}),
  );

  Future<T> delete<T>(String path, {Object? data}) => _unwrap<T>(
    () => _dio.delete<dynamic>(path, data: data ?? const <String, dynamic>{}),
  );

  /// Multipart upload (photo/document). A FormData can only be sent once, so
  /// [build] makes a fresh one for the single retry after a token refresh.
  Future<T> upload<T>(String path, FormData Function() build) async {
    try {
      return await _unwrap<T>(() => _dio.post<dynamic>(path, data: build()));
    } on ApiException catch (e) {
      if (e.statusCode != null && e.statusCode != 401) rethrow;
      return _unwrap<T>(() => _dio.post<dynamic>(path, data: build()));
    }
  }

  Future<T> _unwrap<T>(Future<Response<dynamic>> Function() send) async {
    try {
      final Response<dynamic> response = await send();
      final dynamic body = response.data;
      if (body is Map && body['success'] == true) return body['data'] as T;
      throw ApiException.network;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final dynamic body = e.response?.data;
    if (body is Map && body['error'] is Map) {
      final Map<dynamic, dynamic> error =
          body['error'] as Map<dynamic, dynamic>;
      return ApiException(
        (error['code'] as String?) ?? 'UNKNOWN',
        (error['message'] as String?) ??
            'Something went wrong. Please try again.',
        statusCode: e.response?.statusCode,
      );
    }
    return ApiException.network;
  }
}
