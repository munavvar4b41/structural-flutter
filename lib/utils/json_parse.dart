/// Helpers for decoding Laravel JSON where numbers may arrive as int or double.
int jsonInt(dynamic value, {required String field}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String && value.isNotEmpty) {
    return int.parse(value);
  }
  throw FormatException('Expected int for $field, got ${value.runtimeType}');
}

int? jsonIntOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String && value.isNotEmpty) {
    return int.parse(value);
  }
  return null;
}

bool jsonBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return defaultValue;
}
