import 'package:borrow_ledger/core/services/app_lock_service.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_lock_screen.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;
  final AppLockService? service;
  final Duration lockAfter;
  final DateTime Function()? now;

  const AppLockGate({
    super.key,
    required this.child,
    this.service,
    this.lockAfter = const Duration(minutes: 1),
    this.now,
  });

  static AppLockGateState? of(BuildContext context) {
    return context.findAncestorStateOfType<AppLockGateState>();
  }

  @override
  State<AppLockGate> createState() => AppLockGateState();
}

class AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  late final AppLockService _service;
  late final DateTime Function() _now;
  bool _appReady = false;
  bool _locked = false;
  bool _privacyCoverVisible = false;
  bool _authenticationInProgress = false;
  bool _authenticationScheduled = false;
  bool _wasEnabled = false;
  DateTime? _backgroundedAt;
  AppLockAuthStatus? _lastAuthStatus;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AppLockService.instance;
    _now = widget.now ?? DateTime.now;
    _wasEnabled = _service.isEnabled;
    _locked = _service.isEnabled;
    _service.addListener(_onServiceChanged);
    WidgetsBinding.instance.addObserver(this);
    if (!_service.isInitialized && !_service.initializationFailed) {
      _initializeService();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  Future<void> _initializeService() async {
    await _service.initialize();
    if (!mounted) return;
    if (_service.isEnabled && _appReady) {
      _lockAndPrompt();
    }
    setState(() {});
  }

  void markAppReady() {
    if (_appReady || !mounted) return;
    setState(() => _appReady = true);
    if (_service.isEnabled) _lockAndPrompt();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    final enabled = _service.isEnabled;
    if (!enabled) {
      setState(() {
        _locked = false;
        _privacyCoverVisible = false;
        _lastAuthStatus = null;
      });
    } else if (!_wasEnabled && _appReady) {
      // Enabling the setting already required successful device
      // authentication, so do not immediately prompt the same user again.
      setState(() {
        _locked = false;
        _lastAuthStatus = null;
      });
    } else {
      setState(() {});
    }
    _wasEnabled = enabled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_service.isEnabled || !_appReady) return;

    switch (state) {
      case AppLifecycleState.inactive:
        _setPrivacyCover(true);
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundedAt ??= _now();
        _setPrivacyCover(true);
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        _setPrivacyCover(false);
        if (_authenticationInProgress) return;
        if (backgroundedAt != null &&
            _now().difference(backgroundedAt) >= widget.lockAfter) {
          _lockAndPrompt();
        } else if (_locked) {
          _scheduleAuthentication();
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  void _setPrivacyCover(bool visible) {
    if (!mounted || _privacyCoverVisible == visible) return;
    setState(() => _privacyCoverVisible = visible);
  }

  void _lockAndPrompt() {
    if (!mounted || !_service.isEnabled) return;
    setState(() {
      _locked = true;
      _lastAuthStatus = null;
    });
    _scheduleAuthentication();
  }

  void _scheduleAuthentication() {
    if (_authenticationInProgress ||
        _authenticationScheduled ||
        !_locked ||
        !mounted) {
      return;
    }
    _authenticationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticationScheduled = false;
      if (mounted) _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_authenticationInProgress || !_locked || !mounted) return;
    final tr = AppLocalizations.of(context);
    if (tr == null) return;

    setState(() {
      _authenticationInProgress = true;
      _lastAuthStatus = null;
    });
    final result = await _service.authenticate(
      localizedReason: tr.appLockAuthenticationReason,
    );
    if (!mounted) return;

    setState(() {
      _authenticationInProgress = false;
      _lastAuthStatus = result.status;
      if (result.isAuthenticated) {
        _locked = false;
        _privacyCoverVisible = false;
        _backgroundedAt = null;
      }
    });
  }

  String? _authenticationMessage(AppLocalizations tr) {
    return switch (_lastAuthStatus) {
      AppLockAuthStatus.cancelled => tr.appLockAuthenticationCancelled,
      AppLockAuthStatus.unavailable => tr.appLockAuthenticationUnavailable,
      AppLockAuthStatus.lockedOut => tr.appLockAuthenticationLockedOut,
      AppLockAuthStatus.failed => tr.appLockAuthenticationFailed,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final showLock = _appReady && _locked && _service.isEnabled;
    final showError = _appReady && _service.initializationFailed;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_privacyCoverVisible && !showLock && !showError)
          const Positioned.fill(child: _PrivacyCover()),
        if (showLock && tr != null)
          Positioned.fill(
            child: AppLockScreen(
              isAuthenticating: _authenticationInProgress,
              message: _authenticationMessage(tr),
              onUnlock: _authenticate,
            ),
          ),
        if (showError)
          Positioned.fill(child: _InitializationErrorScreen(onRetry: _retry)),
      ],
    );
  }

  Future<void> _retry() async {
    await _service.initialize(force: true);
    if (!mounted) return;
    if (_service.isEnabled && _appReady) _lockAndPrompt();
    setState(() {});
  }
}

class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: Center(
        child: Icon(
          Icons.lock_outline_rounded,
          size: 44,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _InitializationErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _InitializationErrorScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_reset_rounded,
                  color: AppTheme.warningColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  tr.appLockSettingsLoadFailed,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(tr.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
