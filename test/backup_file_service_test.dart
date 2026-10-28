import 'dart:io';
import 'dart:typed_data';

import 'package:borrow_ledger/core/services/backup_file_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'saveBackup delegates bytes and filename to the platform adapter',
    () async {
      String? savedName;
      Uint8List? savedBytes;

      final service = BackupFileService(
        saveFile: ({required fileName, required bytes}) async {
          savedName = fileName;
          savedBytes = bytes;
          return '/selected/$fileName';
        },
      );

      final bytes = Uint8List.fromList([1, 2, 3]);
      final path = await service.saveBackup(
        fileName: 'backup.blbackup',
        bytes: bytes,
      );

      expect(path, '/selected/backup.blbackup');
      expect(savedName, 'backup.blbackup');
      expect(savedBytes, bytes);
    },
  );

  test('cancelled save returns null without creating a success path', () async {
    final service = BackupFileService(
      saveFile: ({required fileName, required bytes}) async => null,
    );

    final path = await service.saveBackup(
      fileName: 'backup.blbackup',
      bytes: Uint8List(0),
    );

    expect(path, isNull);
  });

  test('shareBackup delegates backup bytes and sharing metadata', () async {
    String? sharedName;
    Uint8List? sharedBytes;
    String? sharedText;
    String? sharedSubject;

    final service = BackupFileService(
      shareFile:
          ({
            required fileName,
            required bytes,
            required text,
            required subject,
          }) async {
            sharedName = fileName;
            sharedBytes = bytes;
            sharedText = text;
            sharedSubject = subject;
          },
    );

    final bytes = Uint8List.fromList([10, 11]);
    await service.shareBackup(
      fileName: 'backup.blbackup',
      bytes: bytes,
      text: 'HisaabMate backup',
      subject: 'Backup',
    );

    expect(sharedName, 'backup.blbackup');
    expect(sharedBytes, bytes);
    expect(sharedText, 'HisaabMate backup');
    expect(sharedSubject, 'Backup');
  });

  test('backup selection reads bytes supplied by a content provider', () async {
    final selection = BackupFileSelection(
      name: 'backup.blbackup',
      bytes: Uint8List.fromList([4, 5, 6]),
    );

    expect(await selection.readBytes(), [4, 5, 6]);
  });

  test('backup selection reads bytes from a filesystem path', () async {
    final directory = await Directory.systemTemp.createTemp('hisaabmate_test_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/backup.blbackup');
    await file.writeAsBytes([7, 8, 9]);

    final selection = BackupFileSelection(
      name: file.uri.pathSegments.last,
      path: file.path,
    );

    expect(await selection.readBytes(), [7, 8, 9]);
  });
}
