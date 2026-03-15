import 'package:flutter/material.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';

/// A metric display card with an icon, value, label and optional gradient.
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? color;
  final Gradient? gradient;
  final Widget? trailing;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color,
    this.gradient,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primary;
    final isDark = gradient != null;
    final textColor = isDark ? Colors.white : effectiveColor;
    final labelColor = isDark ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null
              ? Theme.of(context).cardTheme.color
              : null,
          borderRadius: BorderRadius.circular(16),
          border: gradient == null
              ? Border.all(color: Theme.of(context).colorScheme.outlineVariant)
              : null,
          boxShadow: gradient != null
              ? [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : effectiveColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isDark ? Colors.white : effectiveColor, size: 20),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: labelColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
