// AC1: CUANDO la app arranca con el tema Claro u Oscuro guardado ENTONCES el primer cuadro ya se pinta con ese tema de Portadora, aunque el sistema esté en el otro, sin pasar por el tema del sistema.
// AC2: CUANDO el tema guardado es Auto, no hay nada guardado o no se pudieron leer las preferencias ENTONCES la app arranca igual y sigue el tema claro u oscuro del sistema, también si el sistema cambia con la app abierta.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/bootstrap.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('createAppContainer', () {
    for (final theme in [ThemePreference.dark, ThemePreference.light]) {
      test('AC1: devuelve las preferencias ya leídas con el tema guardado '
          '(${theme.name})', () async {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferencesRepositoryImpl.themePreferenceKey: theme.name,
            });

        final container = await createAppContainer();
        addTearDown(container.dispose);

        final preferences = container.read(preferencesProvider);
        expect(preferences.isLoading, isFalse);
        expect(preferences.value?.themePreference, theme);
      });
    }

    test('AC2: sin nada guardado devuelve el tema Auto ya leído', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();

      final container = await createAppContainer();
      addTearDown(container.dispose);

      final preferences = container.read(preferencesProvider);
      expect(preferences.isLoading, isFalse);
      expect(preferences.value?.themePreference, ThemePreference.auto);
    });

    test(
      'AC2: sin almacenamiento disponible termina igual, sin lanzar',
      () async {
        SharedPreferencesAsyncPlatform.instance = null;

        final container = await createAppContainer();
        addTearDown(container.dispose);

        expect(container.read(preferencesProvider).isLoading, isFalse);
      },
    );
  });
}
