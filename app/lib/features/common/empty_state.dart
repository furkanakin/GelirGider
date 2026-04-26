import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';

class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconBg;
  final Color? iconColor;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconBg,
    this.iconColor,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: iconBg ?? T.terraTint,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: EviIcon(icon, size: 36, color: iconColor ?? T.terracotta, stroke: 1.5),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: TLText.display(20)),
            const SizedBox(height: 6),
            Text(description, textAlign: TextAlign.center, style: TLText.body(color: T.inkMute, weight: FontWeight.w400)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: T.terracotta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(actionLabel!, style: TLText.body(color: Colors.white, weight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? radius;
  const LoadingSkeleton({super.key, this.height = 16, this.width, this.radius});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: T.lineSoft,
        borderRadius: radius ?? BorderRadius.circular(8),
      ),
    );
  }
}
