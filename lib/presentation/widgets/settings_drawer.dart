import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:borrow_ledger/presentation/screens/splash_screen.dart';
import 'package:borrow_ledger/presentation/widgets/clear_data_dialog.dart';
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
import '../cubit/theme_cubit.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Drawer(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            _buildModernHeader(context, colorScheme, isDark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  const SizedBox(height: 24),
                  _buildSectionTitle(tr.appearance, colorScheme),
                  const SizedBox(height: 8),
                  _buildThemeCard(context, colorScheme, isDark),

                  // ✅ ADD THIS SECTION HERE:
                  const SizedBox(height: 24),
                  _buildSectionTitle(tr.language, colorScheme),
                  const SizedBox(height: 8),
                  LanguageSelectorCard(colorScheme: colorScheme),

                  const SizedBox(height: 24),
                  _buildSectionTitle(tr.dataManagement, colorScheme),
                  const SizedBox(height: 8),
                  _buildDataManagementCard(context, colorScheme, isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle(tr.information, colorScheme),
                  const SizedBox(height: 8),
                  _buildAboutCard(context, colorScheme, isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle(tr.dangerZone, colorScheme),
                  const SizedBox(height: 8),
                  _buildDangerCard(context, colorScheme, isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            _buildModernFooter(context, colorScheme, isDark),
          ],
        ),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.lendColor, AppTheme.primaryBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset('assets/images/borrow_ledger_icon.jpeg'),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                tr.appName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              Text(
                tr.appSlogan,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
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
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1,
        ),
      ),
    );
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
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
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
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
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
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.3)),
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 22,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_rounded, size: 14, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Text(
            'Developed By: Sagar Kalel',
            style: TextStyle(
              fontSize: 12,
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

  // EXPORT FUNCTIONALITY
  Future<void> _exportData() async {
    developer.log('🚀 Starting export process...');

    final tr = AppLocalizations.of(context)!;
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr.preparingExport,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

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
        },
        'stats': {
          'total_transactions': transactions.length,
          'total_expenses': expenses.length,
          'total_splits': splits.length,
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
            if (mounted) {
              Navigator.pop(context); // Close loading
              developer.log('❌ Storage permission denied');
              showWarningSnackbar(context, tr.storagePermissionDenied);
            }
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

      if (context.mounted) {
        Navigator.pop(context); // Close loading
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
      }
    } catch (e, stackTrace) {
      developer.log('❌ Export failed: $e');
      developer.log('Stack trace: $stackTrace');

      if (mounted) {
        Navigator.pop(context); // Close loading

        showFailureSnackbar(
          context,
          '${tr.exportFailed}: $e',
          action: SnackBarAction(
            label: tr.retry,
            textColor: Colors.white,
            onPressed: _exportData,
          ),
        );
      }
    }
  }

  // IMPORT FUNCTIONALITY
  Future<void> _importData() async {
    developer.log('🚀 Starting import process...');

    final tr = AppLocalizations.of(context)!;
    try {
      // Pick file
      developer.log('📁 Opening file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        developer.log('❌ No file selected');
        return;
      }

      developer.log('✅ File selected: ${result.files.single.path}');

      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Card(
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr.importingData,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      developer.log('📖 Reading file...');
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      developer.log('✅ File read, size: ${jsonString.length} chars');

      developer.log('🔄 Parsing JSON...');
      final Map<String, dynamic> importData = json.decode(jsonString);
      developer.log('✅ JSON parsed');

      // Validate data structure
      if (!importData.containsKey('data')) {
        developer.log('❌ Invalid backup file: missing "data" key');
        throw Exception('Invalid backup file format - missing data section');
      }

      developer.log('✅ Backup file validated');
      final data = importData['data'] as Map<String, dynamic>;
      final dbHelper = DatabaseHelper();

      // Log what we're about to import
      developer.log('📊 Import contents:');
      developer.log(
        '  - Contacts: ${(data['contacts'] as List?)?.length ?? 0}',
      );
      developer.log(
        '  - Transactions: ${(data['transactions'] as List?)?.length ?? 0}',
      );
      developer.log(
        '  - Expenses: ${(data['expenses'] as List?)?.length ?? 0}',
      );
      developer.log(
        '  - Split Expenses: ${(data['split_expenses'] as List?)?.length ?? 0}',
      );
      developer.log(
        '  - Participants: ${(data['split_participants'] as List?)?.length ?? 0}',
      );

      // Clear existing data
      developer.log('🗑️ Clearing existing data...');
      await dbHelper.clearAllData();
      developer.log('✅ Data cleared');

      // Import all tables
      developer.log('📥 Importing contacts...');
      if (data.containsKey('contacts')) {
        int count = 0;
        for (var contact in data['contacts'] as List) {
          await dbHelper.insert('contacts', contact as Map<String, dynamic>);
          count++;
        }
        developer.log('✅ Imported $count contacts');
      }

      developer.log('📥 Importing transactions...');
      if (data.containsKey('transactions')) {
        int count = 0;
        for (var transaction in data['transactions'] as List) {
          await dbHelper.insert(
            'transactions',
            transaction as Map<String, dynamic>,
          );
          count++;
        }
        developer.log('✅ Imported $count transactions');
      }

      developer.log('📥 Importing expenses...');
      if (data.containsKey('expenses')) {
        int count = 0;
        for (var expense in data['expenses'] as List) {
          await dbHelper.insert('expenses', expense as Map<String, dynamic>);
          count++;
        }
        developer.log('✅ Imported $count expenses');
      }

      developer.log('📥 Importing split expenses...');
      if (data.containsKey('split_expenses')) {
        int count = 0;
        for (var split in data['split_expenses'] as List) {
          await dbHelper.insert(
            'split_expenses',
            split as Map<String, dynamic>,
          );
          count++;
        }
        developer.log('✅ Imported $count split expenses');
      }

      developer.log('📥 Importing split participants...');
      if (data.containsKey('split_participants')) {
        int count = 0;
        for (var participant in data['split_participants'] as List) {
          await dbHelper.insert(
            'split_participants',
            participant as Map<String, dynamic>,
          );
          count++;
        }
        developer.log('✅ Imported $count participants');
      }

      // Reload stats
      developer.log('🔄 Reloading statistics...');
      await Future.delayed(const Duration(seconds: 1));
      developer.log('✅ Statistics reloaded');

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close drawer
        developer.log('✅ Import completed successfully');

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => ImportSuccessDialog(
            transactionsCount: (data['transactions'] as List?)?.length ?? 0,
            splitsCount: (data['split_expenses'] as List?)?.length ?? 0,
            expensesCount: (data['expenses'] as List?)?.length ?? 0,
            onRestart: () => restartApp(context),
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log('❌ Import failed: $e');
      developer.log('Stack trace: $stackTrace');

      if (mounted) {
        Navigator.pop(context); // Close loading
        showFailureSnackbar(context, '${tr.importFailed} $e');
      }
    }
  }

  // HOW IT WORKS DIALOG
  void _showHowItWorksDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: AppTheme.infoColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(tr.howBackupWorks),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr.backupFilesInJson,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.gotIt),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
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
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
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
          text: 'BorrowLedger Backup File\nExported on: $formattedDate',
          subject: 'BorrowLedger Backup ($formattedDate)',
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
      builder: (context) => Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.errorColor),
                SizedBox(height: 16),
                Text(tr.deletingData),
              ],
            ),
          ),
        ),
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
