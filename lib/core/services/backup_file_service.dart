import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

typedef BackupSaveCallback =
    Future<String?> Function({
      required String fileName,
      required Uint8List bytes,
    });

typedef BackupPickCallback = Future<BackupFileSelection?> Function();

typedef BackupShareCallback =
    Future<void> Function({
      required String fileName,
      required Uint8List bytes,
      required String text,
      required String subject,
    });

class BackupFileSelection {
  final String name;
  final String? path;
  final Uint8List? bytes;

  const BackupFileSelection({required this.name, this.path, this.bytes});

  Future<Uint8List> readBytes() async {
    if (bytes != null) return bytes!;
    if (path != null) return File(path!).readAsBytes();
    throw const FormatException('Selected backup file has no readable data.');
  }
}

/// Provides platform-safe backup file operations without broad storage access.
class BackupFileService {
  final BackupSaveCallback _saveFile;
  final BackupPickCallback _pickFile;
  final BackupShareCallback _shareFile;

  BackupFileService({
    BackupSaveCallback? saveFile,
    BackupPickCallback? pickFile,
    BackupShareCallback? shareFile,
  }) : _saveFile = saveFile ?? _saveWithSystemPicker,
       _pickFile = pickFile ?? _pickWithSystemPicker,
       _shareFile = shareFile ?? _shareWithTemporaryFile;

  Future<String?> saveBackup({
    required String fileName,
    required Uint8List bytes,
  }) {
    return _saveFile(fileName: fileName, bytes: bytes);
  }

  Future<BackupFileSelection?> pickBackup() {
    return _pickFile();
  }

  Future<void> shareBackup({
    required String fileName,
    required Uint8List bytes,
    required String text,
    required String subject,
  }) {
    return _shareFile(
      fileName: fileName,
      bytes: bytes,
      text: text,
      subject: subject,
    );
  }

  static Future<String?> _saveWithSystemPicker({
    required String fileName,
    required Uint8List bytes,
  }) {
    return FilePicker.saveFile(
      dialogTitle: 'Save HisaabMate backup',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['blbackup'],
      bytes: bytes,
    );
  }

  static Future<BackupFileSelection?> _pickWithSystemPicker() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['blbackup', 'zip', 'json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    if (file.path == null && file.bytes == null) {
      throw const FormatException('Selected backup file has no readable data.');
    }

    return BackupFileSelection(
      name: file.name,
      path: file.path,
      bytes: file.bytes,
    );
  }

  static Future<void> _shareWithTemporaryFile({
    required String fileName,
    required Uint8List bytes,
    required String text,
    required String subject,
  }) async {
    final temporaryDirectory = await getTemporaryDirectory();
    final file = File('${temporaryDirectory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text, subject: subject),
    );
  }
}
