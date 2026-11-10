import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/lobby/data/datasources/invite_links_datasource.dart';

/// Enlaces de invitación que abren la app.
final inviteLinksProvider = Provider<InviteLinksDataSource>(
  (ref) => InviteLinksDataSource(),
);
