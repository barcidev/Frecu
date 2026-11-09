// F11: CUANDO se pulsa Continuar en los permisos ENTONCES se guarda en las preferencias que el recorrido de la primera vez se completó y se lee igual al reabrir la app; sin nada guardado no está completo, y si el almacenamiento falla el repositorio devuelve un fallo sin lanzar y el provider lo da por no completado.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/permissions/data/repositories/onboarding_repository_impl.dart';
import 'package:frecu/features/permissions/presentation/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Almacenamiento que falla en cualquier lectura o escritura.
class _FailingPreferences extends Fake implements SharedPreferencesAsync {}

void main() {
  OnboardingRepositoryImpl openRepository() =>
      OnboardingRepositoryImpl(preferences: SharedPreferencesAsync());

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('OnboardingRepositoryImpl', () {
    test('F11: sin nada guardado el recorrido no está completo', () async {
      final result = await openRepository().isCompleted();

      expect(result.dataOrNull, isFalse);
    });

    test('F11: completarlo se lee igual al reabrir', () async {
      expect((await openRepository().markCompleted()).isSuccess, isTrue);

      expect((await openRepository().isCompleted()).dataOrNull, isTrue);
    });

    test('F11: si el almacenamiento falla devuelve un fallo', () async {
      final repository = OnboardingRepositoryImpl(
        preferences: _FailingPreferences(),
      );

      expect((await repository.isCompleted()).isFailure, isTrue);
      expect((await repository.markCompleted()).isFailure, isTrue);
    });
  });

  group('OnboardingCompleted', () {
    test(
      'F11: pasa a completado al marcarlo y se conserva al reabrir',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          await container.read(onboardingCompletedProvider.future),
          isFalse,
        );

        await container
            .read(onboardingCompletedProvider.notifier)
            .markCompleted();

        expect(container.read(onboardingCompletedProvider).value, isTrue);
        final reopened = ProviderContainer();
        addTearDown(reopened.dispose);
        expect(await reopened.read(onboardingCompletedProvider.future), isTrue);
      },
    );

    test('F11: si no se puede leer cuenta como no completado y marcarlo cambia '
        'el estado aunque no se guarde', () async {
      final container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(
            OnboardingRepositoryImpl(preferences: _FailingPreferences()),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(onboardingCompletedProvider.future), isFalse);

      final result = await container
          .read(onboardingCompletedProvider.notifier)
          .markCompleted();

      expect(result.isFailure, isTrue);
      expect(container.read(onboardingCompletedProvider).value, isTrue);
    });
  });
}
