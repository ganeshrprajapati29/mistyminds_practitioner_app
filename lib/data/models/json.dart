typedef Json = Map<String, dynamic>;

/// Reads an enum from its wire name (the Dart `.name`), falling back when the
/// server sends a value this build doesn't know yet.
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final T v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

List<String> stringList(Object? value) =>
    (value as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic e) => e.toString())
        .toList();

List<Json> jsonList(Object? value) =>
    (value as List<dynamic>? ?? const <dynamic>[])
        .map(
          (dynamic e) => (e as Map<dynamic, dynamic>).cast<String, dynamic>(),
        )
        .toList();

Json jsonMap(Object? value) =>
    (value as Map<dynamic, dynamic>? ?? const <dynamic, dynamic>{})
        .cast<String, dynamic>();

int asInt(Object? value) => (value as num? ?? 0).round();

double asDouble(Object? value) => (value as num? ?? 0).toDouble();

DateTime asDate(Object? value) => DateTime.parse(value as String).toLocal();
