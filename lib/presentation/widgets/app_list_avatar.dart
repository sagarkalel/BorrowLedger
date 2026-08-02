import 'package:flutter/material.dart';

class AppListAvatar extends StatelessWidget {
  final String label;
  final IconData? indicatorIcon;
  final Color? indicatorColor;
  final IconData? centerIcon;
  final double size;

  const AppListAvatar({
    super.key,
    required this.label,
    this.indicatorIcon,
    this.indicatorColor,
    this.centerIcon,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final avatarBackground = colorScheme.onSurface.withValues(
      alpha: isDark ? 0.12 : 0.07,
    );
    final avatarForeground = colorScheme.onSurfaceVariant;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: avatarBackground,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: centerIcon == null
                    ? Text(
                        label.isNotEmpty ? label[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: avatarForeground,
                        ),
                      )
                    : Icon(centerIcon, size: 20, color: avatarForeground),
              ),
            ),
          ),
          if (indicatorIcon != null && indicatorColor != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: indicatorColor!.withValues(alpha: isDark ? 0.95 : 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Icon(indicatorIcon, size: 9, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
