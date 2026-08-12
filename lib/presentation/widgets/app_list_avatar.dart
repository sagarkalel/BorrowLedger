import 'package:flutter/material.dart';

class AppListAvatar extends StatelessWidget {
  final String label;
  final IconData? indicatorIcon;
  final Color? indicatorColor;
  final bool isSubtleIndicator;
  final IconData? centerIcon;
  final double size;

  const AppListAvatar({
    super.key,
    required this.label,
    this.indicatorIcon,
    this.indicatorColor,
    this.isSubtleIndicator = false,
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
            Builder(
              builder: (context) {
                final indicatorFill = isSubtleIndicator
                    ? colorScheme.surface
                    : indicatorColor!.withValues(alpha: isDark ? 0.95 : 0.9);
                final indicatorBorder = isSubtleIndicator
                    ? indicatorColor!.withValues(alpha: isDark ? 0.45 : 0.35)
                    : colorScheme.surface;
                final indicatorIconColor = isSubtleIndicator
                    ? indicatorColor!.withValues(alpha: isDark ? 0.9 : 0.82)
                    : Colors.white;

                return Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: indicatorFill,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: indicatorBorder,
                        width: isSubtleIndicator ? 1.4 : 2,
                      ),
                    ),
                    child: Icon(
                      indicatorIcon,
                      size: isSubtleIndicator ? 10 : 9,
                      color: indicatorIconColor,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
