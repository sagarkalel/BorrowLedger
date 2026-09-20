import 'dart:io';
import 'dart:typed_data';

import 'package:borrow_ledger/core/services/contact_avatar_service.dart';
import 'package:flutter/material.dart';

class AppListAvatar extends StatelessWidget {
  final String label;
  final IconData? indicatorIcon;
  final Color? indicatorColor;
  final bool isSubtleIndicator;
  final IconData? centerIcon;
  final double size;
  final String? avatar;

  const AppListAvatar({
    super.key,
    required this.label,
    this.indicatorIcon,
    this.indicatorColor,
    this.isSubtleIndicator = false,
    this.centerIcon,
    this.size = 42,
    this.avatar,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _AvatarContent(
                avatar: avatar,
                label: label,
                centerIcon: centerIcon,
                backgroundColor: avatarBackground,
                foregroundColor: avatarForeground,
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

class _AvatarContent extends StatelessWidget {
  final String? avatar;
  final String label;
  final IconData? centerIcon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _AvatarContent({
    required this.avatar,
    required this.label,
    required this.centerIcon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = _AvatarFallback(
      label: label,
      centerIcon: centerIcon,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
    if (centerIcon != null || avatar == null || avatar!.trim().isEmpty) {
      return fallback;
    }

    final service = ContactAvatarService.instance;
    final legacyBytes = service.decodeLegacyBase64(avatar);
    if (legacyBytes != null) {
      return _AvatarImage.memory(bytes: legacyBytes, fallback: fallback);
    }

    return FutureBuilder<File?>(
      future: service.resolveAvatarFile(avatar),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) return fallback;
        return _AvatarImage.file(file: file, fallback: fallback);
      },
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final File? file;
  final Uint8List? bytes;
  final Widget fallback;

  const _AvatarImage.file({required this.file, required this.fallback})
    : bytes = null;

  const _AvatarImage.memory({required this.bytes, required this.fallback})
    : file = null;

  @override
  Widget build(BuildContext context) {
    if (file != null) {
      return Image.file(
        file!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    if (bytes != null) {
      return Image.memory(
        bytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return fallback;
  }
}

class _AvatarFallback extends StatelessWidget {
  final String label;
  final IconData? centerIcon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _AvatarFallback({
    required this.label,
    required this.centerIcon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: Center(
        child: centerIcon == null
            ? Text(
                label.isNotEmpty ? label[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: foregroundColor,
                ),
              )
            : Icon(centerIcon, size: 20, color: foregroundColor),
      ),
    );
  }
}
