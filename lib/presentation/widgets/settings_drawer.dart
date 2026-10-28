import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/services/backup_file_service.dart';
import 'package:borrow_ledger/core/services/backup_crypto_service.dart';
import 'package:borrow_ledger/core/services/app_info_service.dart';
import 'package:borrow_ledger/core/services/app_lock_service.dart';
import 'package:borrow_ledger/core/services/upi_service.dart';
import 'package:borrow_ledger/core/services/contact_avatar_service.dart';
import 'package:borrow_ledger/core/utils/form_input_utils.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/screens/splash_screen.dart';
import 'package:borrow_ledger/presentation/widgets/clear_data_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/app_dialog_components.dart';
import 'package:borrow_ledger/presentation/widgets/backup_password_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/export_data_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/export_success_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/import_data_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/import_success_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/info_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/legacy_backup_warning_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/language_selector_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../cubit/theme_cubit.dart';

class _ParsedBackup {
  final Map<String, List<Map<String, dynamic>>> rows;
  final Directory? extractedAvatarDirectory;

  const _ParsedBackup({required this.rows, this.extractedAvatarDirectory});
}

class SettingsDrawer extends StatefulWidget {
  final bool focusSecurityOnOpen;
  final VoidCallback? onSecurityFocused;

  const SettingsDrawer({
    super.key,
    this.focusSecurityOnOpen = false,
    this.onSecurityFocused,
  });

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  UserProfileModel _userProfile = const UserProfileModel(name: '');
  bool _appLockToggleInProgress = false;
  final GlobalKey _securityCardKey = GlobalKey();
  Timer? _securityHighlightTimer;
  bool _securityHighlighted = false;
  bool _securityFocusRequestHandled = false;
  final BackupFileService _backupFileService = BackupFileService();
  final BackupCryptoService _backupCryptoService = const BackupCryptoService();

  static const List<String> _backupInsertOrder = [
    'contacts',
    'transactions',
    'expenses',
    'split_expenses',
    'split_participants',
    'split_bills',
    'udhari_items',
    'udhari_quantities',
    'shared_spend_purposes',
  ];

  static const List<String> _backupDeleteOrder = [
    'split_bills',
    'split_participants',
    'split_expenses',
    'expenses',
    'transactions',
    'contacts',
    'udhari_items',
    'udhari_quantities',
    'shared_spend_purposes',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    if (widget.focusSecurityOnOpen) _scheduleSecurityFocus();
  }

  @override
  void didUpdateWidget(covariant SettingsDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.focusSecurityOnOpen && oldWidget.focusSecurityOnOpen) {
      _securityFocusRequestHandled = false;
    }
    if (widget.focusSecurityOnOpen &&
        !oldWidget.focusSecurityOnOpen &&
        !_securityFocusRequestHandled) {
      _scheduleSecurityFocus();
    }
  }

  @override
  void dispose() {
    _securityHighlightTimer?.cancel();
    super.dispose();
  }

  void _scheduleSecurityFocus() {
    if (_securityFocusRequestHandled) return;
    _securityFocusRequestHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !widget.focusSecurityOnOpen) return;
      final targetContext = _securityCardKey.currentContext;
      if (targetContext == null) {
        _securityFocusRequestHandled = false;
        _scheduleSecurityFocus();
        return;
      }

      setState(() => _securityHighlighted = true);
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.35,
      );
      if (!mounted) return;
      widget.onSecurityFocused?.call();
      _securityHighlightTimer?.cancel();
      _securityHighlightTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _securityHighlighted = false);
      });
    });
  }

  Future<void> _loadUserProfile() async {
    final profile = await context.read<UserProfileRepository>().getProfile();
    if (!mounted) return;
    setState(() => _userProfile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Drawer(
      child: Column(
        children: [
          _buildModernHeader(context, colorScheme, isDark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                const SizedBox(height: 12),
                _buildSectionTitle(tr.yourProfile, colorScheme),
                const SizedBox(height: 6),
                _buildProfileCard(context, colorScheme),
                const SizedBox(height: 16),
                _buildSectionTitle(tr.appearance, colorScheme),
                const SizedBox(height: 6),
                _buildThemeCard(context, colorScheme, isDark),
                const SizedBox(height: 16),
                _buildSectionTitle(tr.language, colorScheme),
                const SizedBox(height: 6),
                LanguageSelectorCard(colorScheme: colorScheme),
                const SizedBox(height: 16),
                _buildSectionTitle(tr.dataManagement, colorScheme),
                const SizedBox(height: 6),
                _buildDataManagementCard(context, colorScheme, isDark),
                const SizedBox(height: 16),
                _buildSectionTitle(tr.security, colorScheme),
                const SizedBox(height: 6),
                _buildSecurityCard(context, colorScheme),
                const SizedBox(height: 16),
                _buildSectionTitle(tr.information, colorScheme),
                const SizedBox(height: 6),
                _buildAboutCard(context, colorScheme, isDark),
                const SizedBox(height: 16),
                _buildSectionTitle(tr.dangerZone, colorScheme),
                const SizedBox(height: 6),
                _buildDangerCard(context, colorScheme, isDark),
                const SizedBox(height: 12),
              ],
            ),
          ),
          _buildModernFooter(context, colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildModernHeader(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final tr = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: isDark ? 0.18 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset('assets/images/hisaab_mate_icon.png'),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                tr.appName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tr.appSlogan,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, ColorScheme colorScheme) {
    final tr = AppLocalizations.of(context)!;
    final hasName = _userProfile.hasName;
    final title = hasName ? _userProfile.name : tr.setYourName;
    final subtitle = hasName
        ? (_userProfile.phone ?? tr.nameUsedInSharedSplits)
        : tr.helpFriendsRecognizeYou;

    return Card(
      child: _buildActionTile(
        context,
        Icons.account_circle_rounded,
        title,
        subtitle,
        colorScheme.primary,
        colorScheme,
        onTap: () => _showProfileDialog(context),
      ),
    );
  }

  Future<void> _showProfileDialog(BuildContext context) async {
    final tr = AppLocalizations.of(context)!;
    final repository = context.read<UserProfileRepository>();
    final profile = await showDialog<UserProfileModel>(
      context: context,
      builder: (_) => _UserProfileDialog(
        initialProfile: _userProfile,
        repository: repository,
      ),
    );

    if (profile == null || !mounted || !context.mounted) return;
    setState(() => _userProfile = profile);
    showSuccessSnackbar(context, tr.profileSaved);
  }

  Widget _buildThemeCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final tr = AppLocalizations.of(context)!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                _buildThemeOption(
                  context,
                  Icons.light_mode_rounded,
                  tr.lightMode,
                  tr.brightAndClean,
                  ThemeMode.light,
                  themeMode,
                  colorScheme,
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                _buildThemeOption(
                  context,
                  Icons.dark_mode_rounded,
                  tr.darkMode,
                  tr.easyOnEyes,
                  ThemeMode.dark,
                  themeMode,
                  colorScheme,
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                _buildThemeOption(
                  context,
                  Icons.brightness_auto_rounded,
                  tr.systemDefault,
                  tr.followDeviceSettings,
                  ThemeMode.system,
                  themeMode,
                  colorScheme,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    IconData icon,
    String label,
    String subtitle,
    ThemeMode value,
    ThemeMode currentMode,
    ColorScheme colorScheme,
  ) {
    final isSelected = value == currentMode;
    return InkWell(
      onTap: () => context.read<ThemeCubit>().setTheme(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.14)
                    : colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: colorScheme.primary,
                size: 20,
              )
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final tr = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        children: [
          _buildActionTile(
            context,
            Icons.cloud_upload_rounded,
            tr.exportData,
            tr.createBackup,
            AppTheme.successColor,
            colorScheme,
            onTap: () => _showExportDialog(context),
          ),
          Divider(
            height: 1,
            indent: 68,
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
          _buildActionTile(
            context,
            Icons.cloud_download_rounded,
            tr.importData,
            tr.restoreFromBackup,
            colorScheme.secondary,
            colorScheme,
            onTap: () => _showImportDialog(context),
          ),
          Divider(
            height: 1,
            indent: 68,
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
          _buildActionTile(
            context,
            Icons.help_outline_rounded,
            tr.howItWorks,
            tr.learnBackupRestore,
            AppTheme.infoColor,
            colorScheme,
            onTap: () => _showHowItWorksDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final tr = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        children: [
          _buildActionTile(
            context,
            Icons.info_outline_rounded,
            tr.version,
            'v${AppInfoService.instance.fullVersion}',
            colorScheme.primary,
            colorScheme,
            onTap: null,
          ),
          Divider(
            height: 1,
            indent: 68,
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
          _buildActionTile(
            context,
            Icons.description_outlined,
            tr.termsOfService,
            tr.viewTermsAndConditions,
            AppTheme.splitColor,
            colorScheme,
            onTap: () => _showInfoDialog(
              context,
              tr.termsOfService,
              tr.termsOfServiceContent,
              Icons.description_outlined,
              AppTheme.splitColor,
            ),
          ),
          Divider(
            height: 1,
            indent: 68,
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
          _buildActionTile(
            context,
            Icons.privacy_tip_outlined,
            tr.privacyPolicy,
            tr.yourDataStaysOnDevice,
            AppTheme.infoColor,
            colorScheme,
            onTap: () => _showInfoDialog(
              context,
              tr.privacyPolicy,
              tr.privacyPolicyContent,
              Icons.privacy_tip_outlined,
              AppTheme.infoColor,
              actionLabel: tr.openPrivacyPolicy,
              onAction: () => _openPrivacyPolicy(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context, ColorScheme colorScheme) {
    final tr = AppLocalizations.of(context)!;
    final service = AppLockService.instance;
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final enabled = service.isEnabled;
        final subtitle = service.initializationFailed
            ? tr.appLockSettingsLoadFailed
            : enabled
            ? tr.appLockEnabledSubtitle
            : tr.appLockDisabledSubtitle;
        return AnimatedContainer(
          key: _securityCardKey,
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.all(_securityHighlighted ? 2 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _securityHighlighted
                  ? colorScheme.primary
                  : Colors.transparent,
              width: _securityHighlighted ? 1.5 : 0,
            ),
          ),
          child: Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile.adaptive(
              value: enabled,
              secondary: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              title: Text(
                tr.appLock,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              onChanged:
                  _appLockToggleInProgress || service.initializationFailed
                  ? null
                  : (value) => _toggleAppLock(context, value),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleAppLock(BuildContext context, bool enabled) async {
    if (_appLockToggleInProgress) return;
    setState(() => _appLockToggleInProgress = true);
    final tr = AppLocalizations.of(context)!;
    try {
      final result = await AppLockService.instance.setEnabled(
        enabled: enabled,
        localizedReason: tr.appLockAuthenticationReason,
      );
      if (!mounted || !context.mounted || result.isAuthenticated) return;

      final message = switch (result.status) {
        AppLockAuthStatus.cancelled => tr.appLockAuthenticationCancelled,
        AppLockAuthStatus.unavailable => tr.appLockAuthenticationUnavailable,
        AppLockAuthStatus.lockedOut => tr.appLockAuthenticationLockedOut,
        AppLockAuthStatus.failed => tr.appLockAuthenticationFailed,
        AppLockAuthStatus.authenticated => null,
      };
      if (message != null) showWarningSnackbar(context, message);
    } finally {
      if (mounted) setState(() => _appLockToggleInProgress = false);
    }
  }

  Widget _buildDangerCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final tr = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      color: AppTheme.errorColor.withValues(alpha: isDark ? 0.1 : 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.22)),
      ),
      child: _buildActionTile(
        context,
        Icons.delete_forever_rounded,
        tr.clearAllData,
        tr.clearAllDataMessage,
        AppTheme.errorColor,
        colorScheme,
        onTap: _showClearDataDialog,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    ColorScheme colorScheme, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFooter(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code_rounded,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            'Developed By: Sagar Haridas Kalel',
            style: TextStyle(
              fontSize: 11.5,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // MODERN DIALOG METHODS

  Future<void> _showExportDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => ExportDataDialog(onConfirm: _exportData),
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => ImportDataDialog(onConfirm: _importData),
    );
  }

  void _showInfoDialog(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        content: content,
        icon: icon,
        color: color,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showFailureSnackbar(context, 'Could not open the privacy policy.');
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => ClearDataDialog(onConfirm: _onDeleteEverything),
    );
  }

  Map<String, List<Map<String, dynamic>>> _parseBackupRows(String jsonString) {
    final decoded = json.decode(jsonString);
    if (decoded is! Map) {
      throw const FormatException('Selected file is not a valid backup.');
    }

    final data = decoded['data'];
    if (data is! Map) {
      throw const FormatException('Backup file is missing app data.');
    }

    final rowsByTable = <String, List<Map<String, dynamic>>>{};
    for (final table in _backupInsertOrder) {
      final rows = data[table];
      if (rows == null) {
        rowsByTable[table] = const [];
        continue;
      }

      if (rows is! List) {
        throw FormatException('Backup table "$table" is invalid.');
      }

      rowsByTable[table] = rows.map((row) {
        if (row is! Map) {
          throw FormatException('Backup table "$table" has invalid records.');
        }
        return Map<String, dynamic>.from(row);
      }).toList();
    }

    return rowsByTable;
  }

  Future<_ParsedBackup> _parseBackupBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    final extension = fileName.toLowerCase();
    if (extension.endsWith(AppConstants.jsonExtension)) {
      final jsonString = utf8.decode(bytes);
      return _ParsedBackup(rows: _parseBackupRows(jsonString));
    }

    if (!extension.endsWith(AppConstants.backupExtension) &&
        !extension.endsWith('.zip')) {
      throw const FormatException('Selected file is not a valid backup.');
    }

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final dataEntry = archive.findFile('data.json');
    if (dataEntry == null) {
      throw const FormatException('Backup file is missing app data.');
    }

    final dataJson = utf8.decode(dataEntry.content);
    final rows = _parseBackupRows(dataJson);
    final tempRoot = await getTemporaryDirectory();
    final tempAvatarDir = Directory(
      '${tempRoot.path}/borrowledger_avatar_import_${DateTime.now().microsecondsSinceEpoch}',
    );
    await tempAvatarDir.create(recursive: true);

    var extractedCount = 0;
    final avatarService = ContactAvatarService.instance;
    for (final entry in archive.files) {
      if (!entry.isFile || !entry.name.startsWith('avatars/')) continue;
      final fileName = entry.name.substring('avatars/'.length);
      if (!avatarService.isSafeArchiveAvatarName(fileName)) {
        throw const FormatException('Backup contains an unsafe avatar file.');
      }
      final content = entry.content;
      if (content.isEmpty ||
          content.length > ContactAvatarService.maxImportAvatarBytes) {
        continue;
      }
      final outFile = File('${tempAvatarDir.path}/$fileName');
      await outFile.writeAsBytes(content, flush: true);
      extractedCount++;
    }

    if (extractedCount == 0) {
      await tempAvatarDir.delete(recursive: true);
      return _ParsedBackup(rows: rows);
    }
    return _ParsedBackup(rows: rows, extractedAvatarDirectory: tempAvatarDir);
  }

  Future<String?> _askForBackupPassword({required bool importing}) {
    return showDialog<String>(
      context: context,
      builder: (context) => BackupPasswordDialog(importing: importing),
    );
  }

  Future<bool> _confirmLegacyBackupImport() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => const LegacyBackupWarningDialog(),
        ) ??
        false;
  }

  Future<void> _replaceAvatarDirectoryFromImport(
    Directory? tempAvatarDir,
  ) async {
    final avatarService = ContactAvatarService.instance;
    await avatarService.clearAllAvatars();
    if (tempAvatarDir == null || !await tempAvatarDir.exists()) return;

    final avatarDir = await avatarService.avatarDirectory();
    await for (final entity in tempAvatarDir.list()) {
      if (entity is! File) continue;
      final fileName = entity.uri.pathSegments.last;
      if (!avatarService.isSafeArchiveAvatarName(fileName)) continue;
      await entity.copy('${avatarDir.path}/$fileName');
    }
    await tempAvatarDir.delete(recursive: true);
  }

  String _backupErrorMessage(Object error, AppLocalizations tr) {
    if (error is BackupAuthenticationException) {
      return tr.incorrectBackupPassword;
    }
    if (error is BackupFormatException) {
      return tr.backupTamperedOrInvalid;
    }
    if (error is FormatException) {
      return error.message;
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _rebuildSplitBillsFromLegacyBackup(
    sqflite.Transaction txn,
  ) async {
    await txn.execute('''
      INSERT INTO split_bills (
        split_id,
        title,
        amount,
        paid_by_user,
        paid_by_contact_id,
        date,
        note,
        created_at,
        updated_at
      )
      SELECT
        id,
        title,
        paid_by_user,
        1,
        NULL,
        date,
        description,
        created_at,
        updated_at
      FROM split_expenses
      WHERE paid_by_user > 0.009
    ''');

    await txn.execute('''
      INSERT INTO split_bills (
        split_id,
        title,
        amount,
        paid_by_user,
        paid_by_contact_id,
        date,
        note,
        created_at,
        updated_at
      )
      SELECT
        se.id,
        se.title,
        sp.expense_paid,
        0,
        sp.contact_id,
        se.date,
        se.description,
        se.created_at,
        se.updated_at
      FROM split_expenses se
      INNER JOIN split_participants sp ON se.id = sp.split_id
      WHERE sp.expense_paid > 0.009
    ''');

    await txn.execute('''
      INSERT INTO split_bills (
        split_id,
        title,
        amount,
        paid_by_user,
        paid_by_contact_id,
        date,
        note,
        created_at,
        updated_at
      )
      SELECT
        se.id,
        se.title,
        se.total_amount,
        1,
        NULL,
        se.date,
        se.description,
        se.created_at,
        se.updated_at
      FROM split_expenses se
      WHERE NOT EXISTS (
        SELECT 1 FROM split_bills sb WHERE sb.split_id = se.id
      )
    ''');
  }

  void _dismissLoadingDialog() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  // EXPORT FUNCTIONALITY
  Future<void> _exportData() async {
    developer.log('🚀 Starting export process...');

    final tr = AppLocalizations.of(context)!;
    var loadingShown = false;
    try {
      final password = await _askForBackupPassword(importing: false);
      if (password == null) return;
      if (!mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AppLoadingDialog(message: tr.preparingExport),
      );
      loadingShown = true;

      developer.log('📊 Fetching database data...');
      final dbHelper = DatabaseHelper();

      // Fetch all data (including contacts for internal relationships)
      final contacts = await dbHelper.query('contacts');
      developer.log('✅ Contacts fetched: ${contacts.length}');

      final transactions = await dbHelper.query('transactions');
      developer.log('✅ Transactions fetched: ${transactions.length}');

      final expenses = await dbHelper.query('expenses');
      developer.log('✅ Expenses fetched: ${expenses.length}');

      final splits = await dbHelper.query('split_expenses');
      developer.log('✅ Splits fetched: ${splits.length}');

      final participants = await dbHelper.query('split_participants');
      developer.log('✅ Participants fetched: ${participants.length}');

      final splitBills = await dbHelper.query('split_bills');
      developer.log('✅ Split bills fetched: ${splitBills.length}');

      final udhariItems = await dbHelper.query('udhari_items');
      developer.log('✅ Udhari items fetched: ${udhariItems.length}');

      final udhariQuantities = await dbHelper.query('udhari_quantities');
      developer.log('✅ Udhari quantities fetched: ${udhariQuantities.length}');

      await dbHelper.ensureSharedSpendPurposeTable();
      final sharedSpendPurposes = await dbHelper.query('shared_spend_purposes');
      developer.log(
        '✅ Shared spend purposes fetched: ${sharedSpendPurposes.length}',
      );

      final exportData = {
        'app': tr.appName,
        'version': AppInfoService.instance.fullVersion,
        'backup_format': 2,
        'exported_at': DateTime.now().toIso8601String(),
        'data': {
          'contacts': contacts,
          'transactions': transactions,
          'expenses': expenses,
          'split_expenses': splits,
          'split_participants': participants,
          'split_bills': splitBills,
          'udhari_items': udhariItems,
          'udhari_quantities': udhariQuantities,
          'shared_spend_purposes': sharedSpendPurposes,
        },
        'stats': {
          'total_transactions': transactions.length,
          'total_expenses': expenses.length,
          'total_splits': splits.length,
          'total_split_bills': splitBills.length,
          'total_udhari_items': udhariItems.length,
          'total_udhari_quantities': udhariQuantities.length,
          'total_shared_spend_purposes': sharedSpendPurposes.length,
        },
      };

      developer.log('🔄 Converting to JSON...');
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      developer.log('✅ JSON created, size: ${jsonString.length} chars');
      final archive = Archive();
      archive.addFile(ArchiveFile.string('data.json', jsonString));

      final avatarService = ContactAvatarService.instance;
      final avatarFiles = <String, File>{};
      for (final contact in contacts) {
        final avatar = contact['avatar'] as String?;
        final avatarName = avatarService.avatarFileNameFromReference(avatar);
        if (avatarName == null || avatarFiles.containsKey(avatarName)) {
          continue;
        }
        final avatarFile = await avatarService.resolveAvatarFile(avatar);
        if (avatarFile != null && await avatarFile.exists()) {
          avatarFiles[avatarName] = avatarFile;
        }
      }

      for (final entry in avatarFiles.entries) {
        final bytes = await entry.value.readAsBytes();
        archive.addFile(
          ArchiveFile('avatars/${entry.key}', bytes.length, bytes),
        );
      }

      final manifest = {
        'format': 'borrowledger_backup',
        'format_version': 2,
        'app_version': AppInfoService.instance.fullVersion,
        'exported_at': exportData['exported_at'],
        'avatar_count': avatarFiles.length,
      };
      archive.addFile(
        ArchiveFile.string(
          'manifest.json',
          const JsonEncoder.withIndent('  ').convert(manifest),
        ),
      );

      final encodedArchive = Uint8List.fromList(ZipEncoder().encode(archive));
      final encryptedBackup = await _backupCryptoService.encrypt(
        payload: encodedArchive,
        password: password,
      );
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName =
          '${AppConstants.exportFilePrefix}$timestamp${AppConstants.backupExtension}';
      developer.log('📝 File name: $fileName');

      if (!mounted) return;
      _dismissLoadingDialog();
      loadingShown = false;

      final savedPath = await _backupFileService.saveBackup(
        fileName: fileName,
        bytes: encryptedBackup,
      );
      if (savedPath == null) {
        developer.log('ℹ️ Export cancelled by user');
        return;
      }

      developer.log('✅ Export completed successfully: $savedPath');
      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => ExportSuccessDialog(
          fileName: fileName,
          transactionsCount: transactions.length,
          splitsCount: splits.length,
          expensesCount: expenses.length,
          onShare: () async {
            Navigator.pop(context);
            await _backupFileService.shareBackup(
              fileName: fileName,
              bytes: encryptedBackup,
              text: tr.encryptedBackupShareWarning,
              subject: tr.appName,
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      developer.log('❌ Export failed: $e');
      developer.log('Stack trace: $stackTrace');

      if (!mounted) return;
      if (loadingShown) _dismissLoadingDialog();

      showFailureSnackbar(
        context,
        '${tr.exportFailed}: ${_backupErrorMessage(e, tr)}',
        action: SnackBarAction(
          label: tr.retry,
          textColor: Colors.white,
          onPressed: _exportData,
        ),
      );
    }
  }

  // IMPORT FUNCTIONALITY
  Future<void> _importData() async {
    developer.log('🚀 Starting import process...');

    final tr = AppLocalizations.of(context)!;
    var loadingShown = false;
    try {
      // Pick file
      developer.log('📁 Opening file picker...');
      final selectedBackup = await _backupFileService.pickBackup();
      if (selectedBackup == null) {
        developer.log('❌ No file selected');
        return;
      }

      developer.log('✅ File selected: ${selectedBackup.name}');

      final selectedBytes = await selectedBackup.readBytes();
      Uint8List bytesToParse = selectedBytes;
      if (_backupCryptoService.isEncryptedEnvelope(selectedBytes)) {
        final password = await _askForBackupPassword(importing: true);
        if (password == null) return;
        bytesToParse = await _backupCryptoService.decrypt(
          envelopeBytes: selectedBytes,
          password: password,
        );
      } else if (!await _confirmLegacyBackupImport()) {
        return;
      }

      // Show loading only after the file is selected, unlocked, and accepted.
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AppLoadingDialog(message: tr.importingData),
      );
      loadingShown = true;

      developer.log('📖 Reading file...');
      final parsedBackup = await _parseBackupBytes(
        bytesToParse,
        _backupCryptoService.isEncryptedEnvelope(selectedBytes)
            ? 'inner.blbackup'
            : selectedBackup.name,
      );
      final backupRows = parsedBackup.rows;
      developer.log('✅ Backup parsed');

      developer.log('✅ Backup file validated');
      final dbHelper = DatabaseHelper();

      // Log what we're about to import
      developer.log('📊 Import contents:');
      developer.log('  - Contacts: ${backupRows['contacts']?.length ?? 0}');
      developer.log(
        '  - Transactions: ${backupRows['transactions']?.length ?? 0}',
      );
      developer.log('  - Expenses: ${backupRows['expenses']?.length ?? 0}');
      developer.log(
        '  - Split Expenses: ${backupRows['split_expenses']?.length ?? 0}',
      );
      developer.log(
        '  - Participants: ${backupRows['split_participants']?.length ?? 0}',
      );
      developer.log(
        '  - Split Bills: ${backupRows['split_bills']?.length ?? 0}',
      );

      await dbHelper.ensureSharedSpendPurposeTable();
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        developer.log('🗑️ Clearing existing data...');
        for (final table in _backupDeleteOrder) {
          await txn.delete(table);
        }
        developer.log('✅ Data cleared');

        for (final table in _backupInsertOrder) {
          final rows = backupRows[table] ?? const <Map<String, dynamic>>[];
          developer.log('📥 Importing $table...');
          for (final row in rows) {
            await txn.insert(table, row);
          }
          developer.log('✅ Imported ${rows.length} rows into $table');
        }

        if ((backupRows['split_bills'] ?? const []).isEmpty &&
            (backupRows['split_expenses'] ?? const []).isNotEmpty) {
          developer.log('🧾 Rebuilding split bill rows for older backup...');
          await _rebuildSplitBillsFromLegacyBackup(txn);
          developer.log('✅ Split bill rows rebuilt');
        }
      });
      if (parsedBackup.extractedAvatarDirectory != null) {
        await _replaceAvatarDirectoryFromImport(
          parsedBackup.extractedAvatarDirectory,
        );
      }

      // Reload stats
      developer.log('🔄 Reloading statistics...');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      developer.log('✅ Statistics reloaded');

      if (!mounted) return;
      _dismissLoadingDialog();
      loadingShown = false;
      Navigator.pop(context); // Close drawer
      developer.log('✅ Import completed successfully');

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => ImportSuccessDialog(
          transactionsCount: backupRows['transactions']?.length ?? 0,
          splitsCount: backupRows['split_expenses']?.length ?? 0,
          expensesCount: backupRows['expenses']?.length ?? 0,
          onRestart: () => restartApp(context),
        ),
      );
    } catch (e, stackTrace) {
      developer.log('❌ Import failed: $e');
      developer.log('Stack trace: $stackTrace');

      if (!mounted) return;
      if (loadingShown) _dismissLoadingDialog();
      showFailureSnackbar(
        context,
        '${tr.importFailed}: ${_backupErrorMessage(e, tr)}',
      );
    }
  }

  // HOW IT WORKS DIALOG
  void _showHowItWorksDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AppDialogShell(
        icon: const AppDialogIcon(
          icon: Icons.help_outline_rounded,
          color: AppTheme.infoColor,
        ),
        title: tr.howBackupWorks,
        content: [
          _buildHowItWorksItem(
            context,
            Icons.cloud_upload_rounded,
            tr.exportData,
            '${tr.createsJsonFile}\n'
            '• ${tr.allTransactionsLendBorrow}\n'
            '• ${tr.allPersonalExpenses}\n'
            '• ${tr.allSplitExpenses}\n'
            '• ${tr.contactReferences}\n\n'
            '${tr.fileSavedLocally}',
            AppTheme.successColor,
            colorScheme,
          ),
          const SizedBox(height: 10),
          _buildHowItWorksItem(
            context,
            Icons.cloud_download_rounded,
            tr.importData,
            '${tr.restoresDataFromBackup}\n'
            '• ${tr.replacesAllCurrentData}\n'
            '• ${tr.importsAllRecords}\n'
            '• ${tr.maintainsRelationships}\n\n'
            '${tr.alwaysExportBeforeImporting}',
            colorScheme.secondary,
            colorScheme,
          ),
          const SizedBox(height: 10),
          _buildHowItWorksItem(
            context,
            Icons.tips_and_updates_rounded,
            tr.bestPractices,
            '• ${tr.exportRegularly}\n'
            '• ${tr.storeInCloudStorage}\n'
            '• ${tr.neverDeleteLastBackup}\n'
            '• ${tr.shareBackupsSecurely}',
            AppTheme.warningColor,
            colorScheme,
          ),
          const SizedBox(height: 10),
          AppDialogNotice(
            color: colorScheme.primary,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr.backupFilesInJson,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        actions: [
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr.gotIt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksItem(
    BuildContext context,
    IconData icon,
    String title,
    String content,
    Color color,
    ColorScheme colorScheme,
  ) {
    return AppDialogNotice(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> restartApp(context) async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (_) => false,
    );
  }

  Future<void> shareExportedData(Uint8List bytes, String fileName) async {
    final tr = AppLocalizations.of(context)!;
    Navigator.pop(context);
    developer.log('📤 Attempting to share file...');

    try {
      final formattedDate = DateFormat(
        AppConstants.dateTimeFormat,
      ).format(DateTime.now());

      await _backupFileService.shareBackup(
        fileName: fileName,
        bytes: bytes,
        text: 'HisaabMate Backup File\nExported on: $formattedDate',
        subject: 'HisaabMate Backup ($formattedDate)',
      );
      developer.log('✅ Share dialog opened');
    } catch (e) {
      developer.log('❌ Share failed: $e');
      if (mounted) showFailureSnackbar(context, '${tr.shareFailed} $e');
    }
  }

  Future<void> _onDeleteEverything() async {
    Navigator.pop(context); // Close dialog
    Navigator.pop(context); // Close drawer
    final tr = AppLocalizations.of(context)!;
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppLoadingDialog(
        message: tr.deletingData,
        color: AppTheme.errorColor,
      ),
    );

    try {
      await DatabaseHelper().clearAllData();

      if (mounted) {
        Navigator.pop(context); // Close loading
        showSuccessSnackbar(context, tr.allDataCleared);
        restartApp(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        showFailureSnackbar(context, '${tr.failedToDelete} $e');
      }
    }
  }
}

class _UserProfileDialog extends StatefulWidget {
  final UserProfileModel initialProfile;
  final UserProfileRepository repository;

  const _UserProfileDialog({
    required this.initialProfile,
    required this.repository,
  });

  @override
  State<_UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<_UserProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _upiIdController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.name);
    _phoneController = TextEditingController(text: widget.initialProfile.phone);
    _upiIdController = TextEditingController(text: widget.initialProfile.upiId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      title: Text(
        tr.yourProfile,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 15, height: 1.15),
              decoration: _profileInputDecoration(
                labelText: tr.yourNameRequired,
                icon: Icons.person_outline_rounded,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return tr.pleaseEnterYourName;
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              style: const TextStyle(fontSize: 15, height: 1.15),
              decoration: _profileInputDecoration(
                labelText: '${tr.phoneNumber} *',
                hintText: tr.enterPhoneNumber,
                icon: Icons.phone_outlined,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: FormInputUtils.phoneInputFormatters,
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isEmpty) {
                  return tr.pleaseEnterPhoneNumber;
                }
                if (!FormInputUtils.isValidOptionalPhone(phone)) {
                  return tr.invalidPhone;
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _upiIdController,
              style: const TextStyle(fontSize: 15, height: 1.15),
              decoration: _profileInputDecoration(
                labelText: tr.upiIdOptional,
                hintText: tr.enterUpiId,
                icon: Icons.payments_outlined,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final upiId = value?.trim() ?? '';
                if (upiId.isEmpty) return null;
                if (!UpiService.isValidUpiId(upiId)) {
                  return tr.invalidUpiId;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            minimumSize: const Size(80, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: Text(tr.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: FilledButton.styleFrom(
            minimumSize: const Size(92, 42),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(tr.save),
        ),
      ],
    );
  }

  InputDecoration _profileInputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      isDense: true,
      labelStyle: const TextStyle(fontSize: 14),
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      prefixIcon: Icon(icon, size: 19),
      prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final profile = UserProfileModel(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      upiId: UpiService.normalizeUpiId(_upiIdController.text),
    );

    await widget.repository.saveProfile(profile);

    if (!mounted) return;
    Navigator.pop(context, profile);
  }
}
