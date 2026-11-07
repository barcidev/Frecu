import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final storage = <String, dynamic>{};

  dynamic handler(Invocation invocation) {
    if (invocation.isSetter) {
      final name = invocation.memberName.toString();
      storage[name] = invocation.positionalArguments.first;
      return null;
    }
    if (invocation.isGetter) {
      final getter = invocation.memberName.toString();
      final setter = getter.replaceFirst('")', '=")');
      if (storage.containsKey(setter)) {
        return storage[setter];
      }
    }
    return null;
  }

  Mock.throwOnMissingStub(exceptionBuilder: handler);

  // Las pruebas que montan la app leen las preferencias guardadas sin el
  // plugin nativo: por defecto, un almacenamiento en memoria vacío.
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();

  await testMain();
}
