import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/utils/form_input_utils.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/screens/splash_screen.dart';
import 'package:borrow_ledger/presentation/widgets/clear_data_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/app_dialog_components.dart';
import 'package:borrow_ledger/presentation/widgets/export_data_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/export_success_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/import_data_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/import_success_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/info_dialog.dart';
import 'package:borrow_ledger/presentation/widgets/language_selector_card.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../cubit/theme_cubit.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  UserProfileModel _userProfile = const UserProfileModel(name: '');

  static const List<String> _backupInsertOrder = [
    'contacts',
    'transactions',
    'expenses',
    'split_expenses',
    'split_participants',
    'udhari_items',
    'udhari_quantities',
  ];

  static const List<String> _backupDeleteOrder = [
    'split_participants',
    'split_expenses',
    'expenses',
    'transactions',
    'contacts',
    'udhari_items',
    'udhari_quantities',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
            'v${AppConstants.appVersion}',
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
            ),
          ),
        ],
      ),
    );
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
            'Developed By: Sagar Kalel',
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
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          InfoDialog(title: title, content: content, icon: icon, color: color),
    );
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

  String _backupErrorMessage(Object error) {
    if (error is FormatException) {
      return error.message;
    }

    return error.toString().replaceFirst('Exception: ', '');
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

      final udhariItems = await dbHelper.query('udhari_items');
      developer.log('✅ Udhari items fetched: ${udhariItems.length}');

      final udhariQuantities = await dbHelper.query('udhari_quantities');
      developer.log('✅ Udhari quantities fetched: ${udhariQuantities.length}');

      final exportData = {
        'app': tr.appName,
        'version': AppConstants.appVersion,
        'exported_at': DateTime.now().toIso8601String(),
        'data': {
          'contacts': contacts,
          'transactions': transactions,
          'expenses': expenses,
          'split_expenses': splits,
          'split_participants': participants,
          'udhari_items': udhariItems,
          'udhari_quantities': udhariQuantities,
        },
        'stats': {
          'total_transactions': transactions.length,
          'total_expenses': expenses.length,
          'total_splits': splits.length,
          'total_udhari_items': udhariItems.length,
          'total_udhari_quantities': udhariQuantities.length,
        },
      };

      developer.log('🔄 Converting to JSON...');
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      developer.log('✅ JSON created, size: ${jsonString.length} chars');

      // Request storage permission for Android
      if (Platform.isAndroid) {
        developer.log('📱 Android detected, requesting permissions...');

        final androidInfo = await DeviceInfoPlugin().androidInfo;
        developer.log('📱 Android SDK: ${androidInfo.version.sdkInt}');

        if (androidInfo.version.sdkInt < 33) {
          final status = await Permission.storage.request();
          developer.log('📱 Storage permission status: $status');

          if (!status.isGranted) {
            if (!mounted) return;
            _dismissLoadingDialog();
            loadingShown = false;
            developer.log('❌ Storage permission denied');
            showWarningSnackbar(context, tr.storagePermissionDenied);
            return;
          }
        }
      }

      // Save file
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName =
          '${AppConstants.exportFilePrefix}$timestamp${AppConstants.jsonExtension}';
      developer.log('📝 File name: $fileName');

      // Get directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        developer.log('📂 Android directory: ${directory?.path}');
      } else {
        directory = await getApplicationDocumentsDirectory();
        developer.log('📂 iOS directory: ${directory.path}');
      }

      if (directory == null) {
        throw Exception('Could not get storage directory');
      }

      // Create a "Backups" subfolder
      final backupDir = Directory('${directory.path}/Backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
        developer.log('📁 Created Backups directory');
      }

      final file = File('${backupDir.path}/$fileName');
      developer.log('💾 Writing to file: ${file.path}');

      await file.writeAsString(jsonString);
      developer.log('✅ File written successfully');

      // Verify file exists
      final exists = await file.exists();
      final size = await file.length();
      developer.log('✅ File exists: $exists, Size: $size bytes');

      if (!mounted) return;
      _dismissLoadingDialog();
      loadingShown = false;
      developer.log('✅ Export completed successfully');

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => ExportSuccessDialog(
          fileName: fileName,
          transactionsCount: transactions.length,
          splitsCount: splits.length,
          expensesCount: expenses.length,
          onShare: () => shareExportedData(file),
        ),
      );
    } catch (e, stackTrace) {
      developer.log('❌ Export failed: $e');
      developer.log('Stack trace: $stackTrace');

      if (!mounted) return;
      if (loadingShown) _dismissLoadingDialog();

      showFailureSnackbar(
        context,
        '${tr.exportFailed}: ${_backupErrorMessage(e)}',
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
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        developer.log('❌ No file selected');
        return;
      }

      developer.log('✅ File selected: ${result.files.single.path}');

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AppLoadingDialog(message: tr.importingData),
      );
      loadingShown = true;

      developer.log('📖 Reading file...');
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      developer.log('✅ File read, size: ${jsonString.length} chars');

      developer.log('🔄 Parsing JSON...');
      final backupRows = _parseBackupRows(jsonString);
      developer.log('✅ JSON parsed');

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
      });

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
        '${tr.importFailed}: ${_backupErrorMessage(e)}',
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

  Future<void> shareExportedData(File file) async {
    final tr = AppLocalizations.of(context)!;
    Navigator.pop(context);
    developer.log('📤 Attempting to share file...');

    try {
      final formattedDate = DateFormat(
        AppConstants.dateTimeFormat,
      ).format(DateTime.now());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'HisaabMate Backup File\nExported on: $formattedDate',
          subject: 'HisaabMate Backup ($formattedDate)',
        ),
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.name);
    _phoneController = TextEditingController(text: widget.initialProfile.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
    );

    await widget.repository.saveProfile(profile);

    if (!mounted) return;
    Navigator.pop(context, profile);
  }
}
