import 'package:flutter_test/flutter_test.dart';
import 'package:structural_flutter/config/desktop_config.dart';

void main() {
  test('normalizeBaseUrl strips trailing slashes', () {
    expect(
      DesktopConfig.normalizeBaseUrl('http://127.0.0.1:8000/'),
      'http://127.0.0.1:8000',
    );
  });
}
