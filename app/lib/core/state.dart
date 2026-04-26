import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/api_client.dart';

final apiProvider = Provider<ApiClient>((_) => ApiClient.instance);

final meProvider = FutureProvider<UserMe>((ref) async => ref.read(apiProvider).me());

final householdProvider = FutureProvider<Household>((ref) async => ref.read(apiProvider).household());

final membersProvider = FutureProvider<List<HouseholdMember>>(
  (ref) async => ref.read(apiProvider).members(),
);

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) async => ref.read(apiProvider).categories(),
);

final transactionsProvider = FutureProvider.family<List<Transaction>, TxQuery>(
  (ref, q) async => ref.read(apiProvider).transactions(
        kind: q.kind,
        actorUserId: q.actorUserId,
        categoryId: q.categoryId,
        since: q.since,
        until: q.until,
        limit: q.limit,
      ),
);

final reportProvider = FutureProvider.family<Report, ReportQuery>(
  (ref, q) async => ref.read(apiProvider).report(scope: q.scope, anchor: q.anchor),
);

final accountsProvider = FutureProvider<List<Account>>(
  (ref) async => ref.read(apiProvider).accounts(),
);

final recurringProvider = FutureProvider<List<RecurringTemplate>>(
  (ref) async => ref.read(apiProvider).recurring(),
);

final notificationsProvider = FutureProvider.family<List<AppNotification>, bool>(
  (ref, onlyUnread) async => ref.read(apiProvider).notifications(onlyUnread: onlyUnread),
);

final unreadCountProvider = FutureProvider<int>((ref) async {
  try {
    final list = await ref.read(apiProvider).notifications(onlyUnread: true);
    return list.length;
  } catch (_) {
    return 0;
  }
});

class TxQuery {
  final String? kind;
  final String? actorUserId;
  final String? categoryId;
  final DateTime? since;
  final DateTime? until;
  final int limit;
  const TxQuery({
    this.kind,
    this.actorUserId,
    this.categoryId,
    this.since,
    this.until,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      other is TxQuery &&
      other.kind == kind &&
      other.actorUserId == actorUserId &&
      other.categoryId == categoryId &&
      other.since == since &&
      other.until == until &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(kind, actorUserId, categoryId, since, until, limit);
}

class ReportQuery {
  final String scope;
  final DateTime? anchor;
  const ReportQuery({this.scope = 'monthly', this.anchor});

  @override
  bool operator ==(Object other) => other is ReportQuery && other.scope == scope && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(scope, anchor);
}
