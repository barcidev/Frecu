import 'dart:async';

import 'package:mocktail/mocktail.dart';

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

  await testMain();
}
