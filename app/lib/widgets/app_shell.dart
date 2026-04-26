import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'evi_icon.dart';
import 'evi_widgets.dart';

const kDesktopBreakpoint = 900.0;

class AppShell extends ConsumerWidget {
  final Widget child;
  final String activeTab; // home | list | add | chart | people
  const AppShell({super.key, required this.child, required this.activeTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= kDesktopBreakpoint;

    if (isDesktop) {
      return _DesktopShell(child: child, activeTab: activeTab);
    }
    return Scaffold(
      backgroundColor: T.cream,
      extendBody: true,
      body: child,
      bottomNavigationBar: _MobileTabBar(active: activeTab),
    );
  }
}

class _DesktopShell extends ConsumerWidget {
  final Widget child;
  final String activeTab;
  const _DesktopShell({required this.child, required this.activeTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hh = ref.watch(householdProvider);
    final me = ref.watch(meProvider);
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: T.cream,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: T.paper,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: T.terracotta, borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: const EviIcon('house-heart', size: 20, color: Colors.white, stroke: 1.8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Evimiz', style: TLText.display(18)),
                            hh.when(
                              data: (h) => Text(h.name, style: TLText.body(color: T.inkMute, size: 10, weight: FontWeight.w400)),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Nav items
                _NavItem(label: 'Genel', icon: 'house-heart', active: activeTab == 'home', onTap: () => context.go('/home')),
                _NavItem(label: 'İşlemler', icon: 'list', active: activeTab == 'list', onTap: () => context.go('/list')),
                _NavItem(label: 'Raporlar', icon: 'pie', active: activeTab == 'chart', onTap: () => context.go('/monthly')),
                _NavItem(label: 'Kategoriler', icon: 'tag', active: false, onTap: () => context.go('/categories')),
                _NavItem(label: 'Aile', icon: 'people', active: activeTab == 'people', onTap: () => context.go('/family')),
                _NavItem(label: 'Hesaplar', icon: 'wallet', active: false, onTap: () => context.push('/accounts')),
                _NavItem(label: 'Tekrar eden', icon: 'refresh', active: false, onTap: () => context.push('/recurring')),
                _NavItem(label: 'Bildirimler', icon: 'bell', active: false, badge: unread, onTap: () => context.push('/notifications')),
                _NavItem(label: 'Ayarlar', icon: 'settings', active: false, onTap: () => context.push('/settings')),

                const Spacer(),

                // FAB-style "Yeni kayıt"
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/add'),
                    icon: const EviIcon('plus', color: Colors.white, size: 16, stroke: 2.2),
                    label: Text('Yeni kayıt', style: TLText.body(color: Colors.white, weight: FontWeight.w600, size: 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: T.terracotta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // User card
                me.when(
                  data: (u) => Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: T.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: T.line),
                    ),
                    child: Row(
                      children: [
                        Avatar(
                          name: u.displayName,
                          size: 32,
                          color: u.avatarColor == null
                              ? T.terraSoft
                              : Color(int.parse('FF${u.avatarColor!.replaceFirst('#', '')}', radix: 16)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.displayName.split(' ').first, style: TLText.body(weight: FontWeight.w600, size: 12)),
                              Text(u.email, style: TLText.body(color: T.inkMute, size: 10, weight: FontWeight.w400), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push('/settings'),
                          icon: EviIcon('menu-dots', size: 16, color: T.inkMute),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox(height: 60),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Right: content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String icon;
  final bool active;
  final int badge;
  final VoidCallback onTap;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? T.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active ? T.shadowSm : null,
          ),
          child: Row(
            children: [
              EviIcon(icon, size: 16, color: active ? T.ink : T.inkMute),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: TLText.body(color: active ? T.ink : T.inkMute, weight: active ? FontWeight.w600 : FontWeight.w500, size: 13))),
              if (badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: T.terracotta, borderRadius: BorderRadius.circular(8)),
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileTabBar extends StatelessWidget {
  final String active;
  const _MobileTabBar({required this.active});

  static const _tabs = [
    ('home', 'house-heart', 'Ev'),
    ('list', 'list', 'İşlemler'),
    ('add', 'plus', ''),
    ('chart', 'pie', 'Rapor'),
    ('people', 'people', 'Aile'),
  ];

  void _go(BuildContext c, String id) {
    switch (id) {
      case 'home': c.go('/home'); break;
      case 'list': c.go('/list'); break;
      case 'add': c.go('/add'); break;
      case 'chart': c.go('/monthly'); break;
      case 'people': c.go('/family'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, T.cream, T.cream],
            stops: const [0, 0.5, 1],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: T.line),
            boxShadow: const [
              BoxShadow(color: Color(0x0F3C2814), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: _tabs.map((tab) {
              final (id, icon, label) = tab;
              if (id == 'add') {
                return Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _go(context, id),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: T.terracotta,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Color(0x66C4593C), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        child: const Center(child: EviIcon('plus', size: 24, color: Colors.white, stroke: 2)),
                      ),
                    ),
                  ),
                );
              }
              final isActive = active == id;
              return Expanded(
                child: InkWell(
                  onTap: () => _go(context, id),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EviIcon(icon, size: 22, color: isActive ? T.terracotta : T.inkMute, stroke: isActive ? 2 : 1.6),
                        if (label.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                              color: isActive ? T.terracotta : T.inkMute,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
