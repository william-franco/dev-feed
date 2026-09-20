import 'package:dev_feed_app/src/common/services/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('skipBootLocationCheck matches kIsWeb', () {
    expect(skipBootLocationCheck, kIsWeb);
  });
}
