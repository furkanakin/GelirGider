import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'evi_icon.dart';

final _trFormat = NumberFormat('#,##0', 'tr_TR');
final _trFormat2 = NumberFormat('#,##0.00', 'tr_TR');

String formatTL(num n, {int decimals = 0, bool sign = false}) {
  final abs = n.abs();
  final s = (decimals > 0 ? _trFormat2 : _trFormat).format(abs);
  if (n < 0) return '−$s';
  return sign ? '+$s' : s;
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final bool ring;
  const Avatar({super.key, required this.name, this.size = 32, this.color, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? T.terraSoft;
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        boxShadow: ring ? [BoxShadow(color: c, spreadRadius: 2.5, blurRadius: 0, offset: Offset.zero)] : null,
        border: ring ? Border.all(color: T.cream, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: T.inkSoft,
          fontFamily: T.ffSans,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class CatChip extends StatelessWidget {
  final Category? category;
  final double size;
  const CatChip({super.key, required this.category, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final c = category;
    if (c == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: T.lineSoft, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: EviIcon('tag', size: size * 0.55, color: T.inkMute, stroke: 1.7),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: EviIcon(c.icon, size: size * 0.55, color: c.color, stroke: 1.7),
    );
  }
}

/// A pill-shaped chip used as filter chip / status badge.
class TagPill extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? foreground;
  final EdgeInsets padding;
  const TagPill({
    super.key,
    required this.label,
    this.background,
    this.foreground,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: background ?? T.paper, borderRadius: BorderRadius.circular(T.rPill)),
      child: Text(label, style: TLText.body(color: foreground ?? T.inkSoft, size: 12, weight: FontWeight.w500)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const SectionHeader({super.key, required this.label, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 20, 10),
      child: Row(
        children: [
          Expanded(child: Text(label.toUpperCase(), style: TLText.label())),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  final String? subtitle;
  final Widget title;
  final Widget? right;
  final VoidCallback? onBack;
  const ScreenHeader({super.key, this.subtitle, required this.title, this.right, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null) ...[
            _RoundIconBtn(icon: 'arrow-left', onTap: onBack),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  Text(subtitle!.toUpperCase(), style: TLText.label()),
                  const SizedBox(height: 2),
                ],
                DefaultTextStyle(style: TLText.display(28), child: title),
              ],
            ),
          ),
          if (right != null) right!,
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? color;
  const _RoundIconBtn({
    required this.icon,
    this.onTap,
    this.background,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(T.rPill),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: background ?? T.paper, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: EviIcon(icon, size: 18, color: color ?? T.inkSoft),
      ),
    );
  }
}

class RoundIconBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? color;
  final bool hasBadge;
  const RoundIconBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.background,
    this.color,
    this.hasBadge = false,
  });
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _RoundIconBtn(icon: icon, onTap: onTap, background: background, color: color),
        if (hasBadge)
          Positioned(
            top: 8,
            right: 9,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: T.terracotta,
                shape: BoxShape.circle,
                border: Border.all(color: background ?? T.paper, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// Hamur tabaka (paper) card surface used everywhere.
class EviCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final BorderSide? border;
  final BorderRadius? radius;
  const EviCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
    this.color,
    this.border,
    this.radius,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? T.surface,
        borderRadius: radius ?? BorderRadius.circular(T.rLg),
        border: Border.fromBorderSide(border ?? BorderSide(color: T.line)),
      ),
      child: child,
    );
  }
}
