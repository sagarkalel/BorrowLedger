import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ContactAvatarService {
  static const String avatarDirectoryName = 'contact_avatars';
  static const int maxDimension = 512;
  static const int jpegQuality = 78;
  static const int maxImportAvatarBytes = 5 * 1024 * 1024;
  static const int maxSavedAvatarBytes = 512 * 1024;

  static final ContactAvatarService instance = ContactAvatarService._();

  ContactAvatarService._();

  Future<Directory> avatarDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, avatarDirectoryName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File?> resolveAvatarFile(String? avatar) async {
    if (avatar == null || avatar.trim().isEmpty || isLegacyBase64(avatar)) {
      return null;
    }

    final normalized = _normalizeReference(avatar);
    if (!_isSafeRelativeAvatarPath(normalized)) return null;

    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, normalized));
    return await file.exists() ? file : null;
  }

  bool isLegacyBase64(String avatar) {
    final value = avatar.trim();
    if (value.isEmpty || value.contains('/') || value.contains(r'\')) {
      return false;
    }
    if (value.length < 80) return false;
    return RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(value);
  }

  Uint8List? decodeLegacyBase64(String? avatar) {
    if (avatar == null || !isLegacyBase64(avatar)) return null;
    try {
      return base64Decode(avatar);
    } catch (_) {
      return null;
    }
  }

  Future<String?> saveAvatarBytes(
    Uint8List bytes, {
    String? oldAvatar,
    String? nameHint,
  }) async {
    if (bytes.isEmpty) return null;

    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: maxDimension,
      minHeight: maxDimension,
      quality: jpegQuality,
      format: CompressFormat.jpeg,
    );
    if (compressed.isEmpty || compressed.length > maxSavedAvatarBytes) {
      return null;
    }

    final dir = await avatarDirectory();
    final fileName = _buildFileName(nameHint);
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(compressed, flush: true);
    if (!await file.exists() || await file.length() == 0) return null;
    await deleteAvatar(oldAvatar);
    return p.join(avatarDirectoryName, fileName);
  }

  Future<String?> savePickedAvatar(XFile picked, {String? oldAvatar}) async {
    final bytes = await picked.readAsBytes();
    return saveAvatarBytes(
      bytes,
      oldAvatar: oldAvatar,
      nameHint: p.basenameWithoutExtension(picked.path),
    );
  }

  Future<void> deleteAvatar(String? avatar) async {
    if (avatar == null || avatar.trim().isEmpty || isLegacyBase64(avatar)) {
      return;
    }
    final file = await resolveAvatarFile(avatar);
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearAllAvatars() async {
    final dir = await avatarDirectory();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  }

  bool isSafeArchiveAvatarName(String name) {
    final normalized = _normalizeReference(name);
    if (normalized.isEmpty ||
        normalized.startsWith('/') ||
        normalized.contains('..') ||
        normalized.contains(r'\')) {
      return false;
    }
    final extension = p.extension(normalized).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp'].contains(extension);
  }

  String? avatarFileNameFromReference(String? avatar) {
    if (avatar == null || avatar.trim().isEmpty || isLegacyBase64(avatar)) {
      return null;
    }
    final normalized = _normalizeReference(avatar);
    if (!_isSafeRelativeAvatarPath(normalized)) return null;
    return p.basename(normalized);
  }

  String _buildFileName(String? nameHint) {
    final safeHint = (nameHint ?? 'avatar')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final prefix = safeHint.isEmpty ? 'avatar' : safeHint;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}.jpg';
  }

  String _normalizeReference(String value) =>
      value.trim().replaceAll('\\', '/');

  bool _isSafeRelativeAvatarPath(String value) {
    if (value.startsWith('/') || value.contains('..')) return false;
    final parts = p.posix.split(value);
    return parts.length == 2 &&
        parts.first == avatarDirectoryName &&
        isSafeArchiveAvatarName(parts.last);
  }
}
