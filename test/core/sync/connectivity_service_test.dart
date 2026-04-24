import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peptilog_app/core/services/connectivity_service.dart';

// ---------------------------------------------------------------------------
// Fake Connectivity that lets tests control the stream.
// ---------------------------------------------------------------------------

class FakeConnectivity implements Connectivity {
  final _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  void emit(List<ConnectivityResult> results) => _controller.add(results);

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.none];

  // Unused methods required by interface.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ConnectivityService', () {
    test('onlineStream emits true for wifi', () async {
      final fake = FakeConnectivity();
      final service = ConnectivityService(fake);
      final values = <bool>[];
      final sub = service.onlineStream.listen(values.add);

      fake.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(values, [true]);
      await sub.cancel();
    });

    test('onlineStream emits true for mobile', () async {
      final fake = FakeConnectivity();
      final service = ConnectivityService(fake);
      final values = <bool>[];
      final sub = service.onlineStream.listen(values.add);

      fake.emit([ConnectivityResult.mobile]);
      await Future<void>.delayed(Duration.zero);

      expect(values, [true]);
      await sub.cancel();
    });

    test('onlineStream emits false for none', () async {
      final fake = FakeConnectivity();
      final service = ConnectivityService(fake);
      final values = <bool>[];
      final sub = service.onlineStream.listen(values.add);

      fake.emit([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);

      expect(values, [false]);
      await sub.cancel();
    });

    test('onlineStream transitions correctly on connectivity changes', () async {
      final fake = FakeConnectivity();
      final service = ConnectivityService(fake);
      final values = <bool>[];
      final sub = service.onlineStream.listen(values.add);

      fake.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      fake.emit([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      fake.emit([ConnectivityResult.mobile]);
      await Future<void>.delayed(Duration.zero);

      expect(values, [true, false, true]);
      await sub.cancel();
    });
  });
}
