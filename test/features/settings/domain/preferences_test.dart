// AC1: CUANDO se leen las preferencias sin nada guardado ENTONCES el nombre visible es nulo, el tema es Auto y el modo de habla por defecto es PTT.
// AC3: CUANDO se guarda un nombre con espacios alrededor ENTONCES se guarda recortado; CUANDO el nombre queda vacío o pasa de 20 caracteres ENTONCES se devuelve un fallo y el nombre guardado no cambia.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';

void main() {
  group('Preferences', () {
    test('AC1: los valores por defecto son sin nombre, tema Auto y PTT', () {
      const preferences = Preferences();

      expect(preferences.displayName, isNull);
      expect(preferences.themePreference, ThemePreference.auto);
      expect(preferences.defaultTalkMode, TalkMode.pushToTalk);
      expect(ThemePreference.values, [
        ThemePreference.auto,
        ThemePreference.light,
        ThemePreference.dark,
      ]);
    });

    test('AC3: el nombre se recorta y solo vale de 1 a 20 caracteres', () {
      expect(Preferences.displayNameMaxLength, 20);
      expect(Preferences.normalizeDisplayName('  Ana  '), 'Ana');
      expect(Preferences.normalizeDisplayName('Íñigo'), 'Íñigo');
      expect(Preferences.normalizeDisplayName('a' * 20), 'a' * 20);
      expect(Preferences.normalizeDisplayName('  ${'b' * 20}  '), 'b' * 20);
      expect(Preferences.normalizeDisplayName(''), isNull);
      expect(Preferences.normalizeDisplayName('   '), isNull);
      expect(Preferences.normalizeDisplayName('a' * 21), isNull);
    });
  });
}
