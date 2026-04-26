import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';
import '../common/empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsProvider(false));
    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              subtitle: 'BİLDİRİMLER',
              title: Text('Olanlar', style: TLText.display(28)),
              onBack: () => context.pop(),
              right: notifs.maybeWhen(
                data: (list) => list.any((n) => !n.isRead)
                    ? TextButton(
                        onPressed: () async {
                          await ref.read(apiProvider).markAllNotificationsRead();
                          ref.invalidate(notificationsProvider);
                          ref.invalidate(unreadCountProvider);
                        },
                        child: Text('Tümünü oku', style: TLText.body(color: T.terracotta, weight: FontWeight.w600, size: 12)),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ),

            Expanded(
              child: notifs.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: 'bell',
                      title: 'Sessizlik',
                      description: 'Bütçe uyarıları, davet kabulleri ve aile etkinlikleri burada görünecek.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadCountProvider);
                      await ref.read(notificationsProvider(false).future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _NotifTile(n: list[i]),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: T.terracotta)),
                error: (e, _) => EmptyState(
                  icon: 'bell',
                  title: 'Yüklenemedi',
                  description: e.toString(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifTile extends ConsumerWidget {
  final AppNotification n;
  const _NotifTile({required this.n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String iconOf(String kind) => switch (kind) {
          'budget_warning' => 'wallet',
          'recurring_due' => 'refresh',
          'invite_accepted' => 'people',
          'tip' => 'sparkle',
          _ => 'bell',
        };
    Color colorOf(String kind) => switch (kind) {
          'budget_warning' => T.alert,
          'recurring_due' => T.terracotta,
          'invite_accepted' => T.forest,
          _ => T.inkSoft,
        };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: n.isRead ? T.surface : T.terraTint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            if (!n.isRead) {
              await ref.read(apiProvider).markNotificationRead(n.id);
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            }
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: n.isRead ? T.line : T.terraSoft),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: EviIcon(iconOf(n.kind), size: 18, color: colorOf(n.kind))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title, style: TLText.body(weight: FontWeight.w600, size: 14)),
                      if (n.body != null && n.body!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(n.body!, style: TLText.body(color: T.inkSoft, size: 13, weight: FontWeight.w400)),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMM HH:mm', 'tr_TR').format(n.createdAt),
                        style: TLText.body(color: T.inkMute, size: 11, weight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                if (!n.isRead)
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: T.terracotta, shape: BoxShape.circle)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
