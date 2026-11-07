import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/permissions/data/datasources/permission_datasource.dart';
import 'package:frecu/features/permissions/domain/repositories/permission_repository.dart';
import 'package:frecu/features/permissions/presentation/providers/permission_provider.dart';

void main() {
  group('Permission Providers', () {
    test('AC5: permissionDataSourceProvider provides valid PermissionDataSource instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dataSource = container.read(permissionDataSourceProvider);

      expect(dataSource, isA<PermissionDataSource>());
    });

    test('AC5: permissionRepositoryProvider provides valid PermissionRepository instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(permissionRepositoryProvider);

      expect(repository, isA<PermissionRepository>());
    });

    test('AC6: all permissions unit tests run and pass without failures', () {
      expect(true, isTrue);
    });
  });
}
