import 'package:flutter/material.dart';

class AppDialogShell extends StatelessWidget {
  final Widget? icon;
  final String title;
  final List<Widget> content;
  final List<Widget> actions;
  final double maxWidth;

  const AppDialogShell({
    super.key,
    this.icon,
    required this.title,
    required this.content,
    required this.actions,
    this.maxWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(height: 14)],
              Text(
                title,
                style:
                    Theme.of(context).dialogTheme.titleTextStyle ??
                    TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
              if (content.isNotEmpty) ...[
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: content,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class AppDialogIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const AppDialogIcon({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class AppDialogNotice extends StatelessWidget {
  final Widget child;
  final Color? color;

  const AppDialogNotice({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final noticeColor = color ?? colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: noticeColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: noticeColor.withValues(alpha: 0.16)),
      ),
      child: child,
    );
  }
}

class AppDialogBullet extends StatelessWidget {
  final String text;
  final Color color;

  const AppDialogBullet({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppLoadingDialog extends StatelessWidget {
  final String message;
  final Color? color;

  const AppLoadingDialog({super.key, required this.message, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progressColor = color ?? colorScheme.primary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: progressColor,
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
