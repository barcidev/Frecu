// AC1: CUANDO se leen las preferencias sin nada guardado ENTONCES el nombre visible es nulo, el tema es Auto y el modo de habla por defecto es PTT.
// AC2: CUANDO se guardan el nombre, el tema y el modo de habla por defecto ENTONCES el provider expone los valores nuevos al instante y, al reabrir la app (un repositorio y un provider nuevos sobre el mismo almacenamiento), se leen los mismos valores.
// AC3: CUANDO se guarda un nombre con espacios alrededor ENTONCES se guarda recortado; CUANDO el nombre queda vacío o pasa de 20 caracteres ENTONCES se devuelve un fallo y el nombre guardado no cambia.
// AC4: CUANDO el almacenamiento falla al leer o escribir, o guarda un valor desconocido ENTONCES el repositorio devuelve `Result.failure` sin lanzar excepciones o usa el valor por defecto, y el provider conserva su estado anterior (o los valores por defecto si falla la lectura).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:frecu/features/settings/domain/repositories/preferences_repository.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Almacenamiento que falla en cualquier lectura o escritura.
class _FailingPreferences extends Fake implements SharedPreferencesAsync {}

class _MockPreferencesRepository extends Mock
    implements PreferencesRepository {}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('preferencesProvider', () {
    test('AC1: sin nada guardado expone sin nombre, tema Auto y PTT', () async {
      final container = ProviderContainer.test();

      final preferences = await container.read(preferencesProvider.future);

      expect(preferences, const Preferences());
      expect(preferences.displayName, isNull);
      expect(preferences.themePreference, ThemePreference.auto);
      expect(preferences.defaultTalkMode, TalkMode.pushToTalk);
    });

    test(
      'AC2: expone al instante lo guardado y lo conserva al reabrir',
      () async {
        final container = ProviderContainer.test();
        final notifier = container.read(preferencesProvider.notifier);

        // Sin esperar la carga: el cambio espera el estado y luego lo aplica.
        final theme = await notifier.setThemePreference(ThemePreference.dark);
        expect(theme.isSuccess, isTrue);
        expect(
          container.read(preferencesProvider).value?.themePreference,
          ThemePreference.dark,
        );

        expect((await notifier.setDisplayName('Ana')).isSuccess, isTrue);
        expect(container.read(preferencesProvider).value?.displayName, 'Ana');

        final talkMode = await notifier.setDefaultTalkMode(TalkMode.openMic);
        expect(talkMode.isSuccess, isTrue);
        expect(
          container.read(preferencesProvider).value?.defaultTalkMode,
          TalkMode.openMic,
        );

        final reopened = ProviderContainer.test();
        expect(
          await reopened.read(preferencesProvider.future),
          const Preferences(
            displayName: 'Ana',
            themePreference: ThemePreference.dark,
            defaultTalkMode: TalkMode.openMic,
          ),
        );
      },
    );

    test('AC3: guarda el nombre recortado y rechaza el vacío o el de más de 20 '
        'caracteres sin cambiar el estado ni lo guardado', () async {
      final container = ProviderContainer.test();
      await container.read(preferencesProvider.future);
      final notifier = container.read(preferencesProvider.notifier);

      expect((await notifier.setDisplayName('  Ana  ')).isSuccess, isTrue);
      expect(container.read(preferencesProvider).value?.displayName, 'Ana');

      expect((await notifier.setDisplayName('   ')).isFailure, isTrue);
      expect((await notifier.setDisplayName('a' * 21)).isFailure, isTrue);
      expect(container.read(preferencesProvider).value?.displayName, 'Ana');

      final reopened = ProviderContainer.test();
      final preferences = await reopened.read(preferencesProvider.future);
      expect(preferences.displayName, 'Ana');
    });

    test(
      'AC4: si falla la lectura expone los valores por defecto y si falla la '
      'escritura conserva el estado',
      () async {
        final container = ProviderContainer.test(
          overrides: [
            preferencesRepositoryProvider.overrideWithValue(
              PreferencesRepositoryImpl(preferences: _FailingPreferences()),
            ),
          ],
        );

        final preferences = await container.read(preferencesProvider.future);
        expect(preferences, const Preferences());

        final notifier = container.read(preferencesProvider.notifier);
        expect(
          (await notifier.setThemePreference(ThemePreference.dark)).isFailure,
          isTrue,
        );
        expect((await notifier.setDisplayName('Ana')).isFailure, isTrue);
        expect(
          (await notifier.setDefaultTalkMode(TalkMode.openMic)).isFailure,
          isTrue,
        );
        expect(container.read(preferencesProvider).value, const Preferences());
      },
    );

    test(
      'AC4: si falla la escritura conserva el estado anterior cargado',
      () async {
        const saved = Preferences(
          displayName: 'Ana',
          themePreference: ThemePreference.light,
        );
        const failure = Failure.unexpected(message: 'disco lleno');
        final repository = _MockPreferencesRepository();
        when(repository.load)
            .thenAnswer((_) async => const Result.success(saved));
        when(() => repository.saveDisplayName('Bea'))
            .thenAnswer((_) async => const Result<String>.failure(failure));
        when(() => repository.saveThemePreference(ThemePreference.dark))
            .thenAnswer((_) async => const Result<void>.failure(failure));
        when(() => repository.saveDefaultTalkMode(TalkMode.openMic))
            .thenAnswer((_) async => const Result<void>.failure(failure));

        final container = ProviderContainer.test(
          overrides: [
            preferencesRepositoryProvider.overrideWithValue(repository),
          ],
        );
        expect(await container.read(preferencesProvider.future), saved);
        final notifier = container.read(preferencesProvider.notifier);

        expect((await notifier.setDisplayName('Bea')).isFailure, isTrue);
        expect(
          (await notifier.setThemePreference(ThemePreference.dark)).isFailure,
          isTrue,
        );
        expect(
          (await notifier.setDefaultTalkMode(TalkMode.openMic)).isFailure,
          isTrue,
        );
        expect(container.read(preferencesProvider).value, saved);
      },
    );
  });
}
