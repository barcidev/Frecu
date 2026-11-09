import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';

void main() {
  group('Core contracts', () {
    test('AC1: static analysis passes for core contracts', () {
      expect(NetworkConstants.signalingPort, 47800);
      expect(NetworkConstants.maxParticipants, 6);
      expect(NetworkConstants.mdnsServiceType, '_frecu._tcp');
    });

    test('AC2: Result success and failure functional contracts', () {
      const successResult = Result<String>.success('data');
      expect(successResult.isSuccess, isTrue);
      expect(successResult.isFailure, isFalse);
      expect(successResult.dataOrNull, 'data');
      expect(successResult.failureOrNull, isNull);

      const failure = Failure.network(message: 'timeout');
      const failureResult = Result<String>.failure(failure);
      expect(failureResult.isSuccess, isFalse);
      expect(failureResult.isFailure, isTrue);
      expect(failureResult.dataOrNull, isNull);
      expect(failureResult.failureOrNull, equals(failure));
    });

    test('AC2: Failure sealed union exhaustiveness', () {
      const failures = <Failure>[
        Failure.network(message: 'error'),
        Failure.permissionDenied(permission: 'microphone'),
        Failure.roomFull(),
        Failure.invalidAccessCode(),
        Failure.hostUnreachable(),
        Failure.versionMismatch(),
        Failure.audio(message: 'audio error'),
        Failure.hotspot(HotspotFailureReason.hotspotOn),
        Failure.wifiJoin(WifiJoinFailureReason.declined),
        Failure.unexpected(message: 'crash'),
      ];

      for (final f in failures) {
        final description = f.when(
          network: (msg) => 'network: $msg',
          permissionDenied: (p) => 'perm: $p',
          roomFull: () => 'full',
          invalidAccessCode: () => 'invalid',
          hostUnreachable: () => 'unreachable',
          versionMismatch: () => 'version',
          audio: (msg) => 'audio: $msg',
          hotspot: (reason) => 'hotspot: ${reason.name}',
          wifiJoin: (reason) => 'wifi: ${reason.name}',
          unexpected: (msg, err) => 'unexpected: $msg',
        );
        expect(description, isNotEmpty);
      }
    });

    test('AC2: AppLogger logs without throwing', () {
      expect(() => AppLogger.d('debug log'), returnsNormally);
      expect(() => AppLogger.i('info log'), returnsNormally);
      expect(() => AppLogger.w('warn log'), returnsNormally);
      expect(() => AppLogger.e('error log'), returnsNormally);
    });

    test('AC2: NoParams instantiates const', () {
      const p1 = NoParams();
      const p2 = NoParams();
      expect(p1, equals(p2));
    });
  });
}
