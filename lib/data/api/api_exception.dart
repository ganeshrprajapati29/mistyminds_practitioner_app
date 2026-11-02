/// A failure the user should be told about. [message] comes straight from the
/// backend's `{success:false, error:{code,message}}` envelope, which is
/// written to be shown as-is — kind and plain.
class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  static const ApiException network = ApiException(
    'NETWORK_ERROR',
    'We couldn’t reach Misty Minds. Please check your connection and try again.',
  );

  @override
  String toString() => message;
}
