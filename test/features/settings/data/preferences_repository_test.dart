// AC1: CUANDO se leen las preferencias sin nada guardado ENTONCES el nombre visible es nulo, el tema es Auto y el modo de habla por defecto es PTT.
// AC2: CUANDO se guardan el nombre, el tema y el modo de habla por defecto ENTONCES el provider expone los valores nuevos al instante y, al reabrir la app (un repositorio y un provider nuevos sobre el mismo almacenamiento), se leen los mismos valores.
// AC3: CUANDO se guarda un nombre con espacios alrededor ENTONCES se guarda recortado; CUANDO el nombre queda vacío o pasa de 20 caracteres ENTONCES se devuelve un fallo y el nombre guardado no cambia.
// AC4: CUANDO el almacenamiento falla al leer o escribir, o guarda un valor desconocido ENTONCES el repositorio devuelve `Result.failure` sin lanzar excepciones o usa el valor por defecto, y el provider conserva su estado anterior (o los valores por defecto si falla la lectura).
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Almacenamiento que falla en cualquier lectura o escritura.
class _FailingPreferences extends Fake implements SharedPreferencesAsync {}

void main() {
  PreferencesRepositoryImpl openRepository() =>
      PreferencesRepositoryImpl(preferences: SharedPreferencesAsync());

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('PreferencesRepositoryImpl', () {
    test('AC1: sin nada guardado lee sin nombre, tema Auto y PTT', () async {
      final result = await openRepository().load();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, const Preferences());
    });

    test(
      'AC2: lo guardado se lee igual al reabrir con un repositorio nuevo',
      () async {
        final repository = openRepository();

        expect((await repository.saveDisplayName('Ana')).isSuccess, isTrue);
        expect(
          (await repository.saveThemePreference(ThemePreference.dark))
              .isSuccess,
          isTrue,
        );
        expect(
          (await repository.saveDefaultTalkMode(TalkMode.openMic)).isSuccess,
          isTrue,
        );

        final reopened = await openRepository().load();

        expect(
          reopened.dataOrNull,
          const Preferences(
            displayName: 'Ana',
            themePreference: ThemePreference.dark,
            defaultTalkMode: TalkMode.openMic,
          ),
        );

        await openRepository().saveThemePreference(ThemePreference.light);
        await openRepository().saveDefaultTalkMode(TalkMode.pushToTalk);
        final changed = await openRepository().load();

        expect(changed.dataOrNull?.themePreference, ThemePreference.light);
        expect(changed.dataOrNull?.defaultTalkMode, TalkMode.pushToTalk);
      },
    );

    test('AC3: guarda el nombre recortado y rechaza el vacío o el de más de 20 '
        'caracteres sin cambiar el guardado', () async {
      final repository = openRepository();

      final saved = await repository.saveDisplayName('  Ana  ');
      expect(saved.isSuccess, isTrue);
      expect(saved.dataOrNull, 'Ana');

      expect((await repository.saveDisplayName('   ')).isFailure, isTrue);
      expect((await repository.saveDisplayName('')).isFailure, isTrue);
      expect((await repository.saveDisplayName('a' * 21)).isFailure, isTrue);

      final reopened = await openRepository().load();
      expect(reopened.dataOrNull?.displayName, 'Ana');
    });

    test(
      'AC4: un valor desconocido guardado se lee como el valor por defecto',
      () async {
        final storage = SharedPreferencesAsync();
        await storage.setString(
          PreferencesRepositoryImpl.displayNameKey,
          '   ',
        );
        await storage.setString(
          PreferencesRepositoryImpl.themePreferenceKey,
          'sepia',
        );
        await storage.setString(
          PreferencesRepositoryImpl.defaultTalkModeKey,
          'shout',
        );

        final result = await openRepository().load();

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, const Preferences());
      },
    );

    test('Vibración: encendida por defecto, se guarda y se lee al reabrir; '
        'un valor desconocido vuelve a encendida', () async {
      expect((await openRepository().load()).dataOrNull?.vibration, isTrue);

      final repository = openRepository();
      expect(
        (await repository.saveVibration(enabled: false)).isSuccess,
        isTrue,
      );
      expect((await openRepository().load()).dataOrNull?.vibration, isFalse);

      await SharedPreferencesAsync().setString(
        PreferencesRepositoryImpl.vibrationKey,
        'quizás',
      );
      expect((await openRepository().load()).dataOrNull?.vibration, isTrue);
    });

    test('Filtro de viento: encendido por defecto, se guarda y se lee al '
        'reabrir; un valor desconocido vuelve a encendido', () async {
      expect((await openRepository().load()).dataOrNull?.windFilter, isTrue);

      final repository = openRepository();
      expect(
        (await repository.saveWindFilter(enabled: false)).isSuccess,
        isTrue,
      );
      expect((await openRepository().load()).dataOrNull?.windFilter, isFalse);

      await SharedPreferencesAsync().setString(
        PreferencesRepositoryImpl.windFilterKey,
        'quizás',
      );
      expect((await openRepository().load()).dataOrNull?.windFilter, isTrue);
    });

    test(
      'AC4: si el almacenamiento falla devuelve Result.failure sin lanzar',
      () async {
        final repository = PreferencesRepositoryImpl(
          preferences: _FailingPreferences(),
        );

        expect((await repository.load()).isFailure, isTrue);
        expect((await repository.saveDisplayName('Ana')).isFailure, isTrue);
        expect(
          (await repository.saveThemePreference(ThemePreference.dark))
              .isFailure,
          isTrue,
        );
        expect(
          (await repository.saveDefaultTalkMode(TalkMode.openMic)).isFailure,
          isTrue,
        );
      },
    );
  });
}
