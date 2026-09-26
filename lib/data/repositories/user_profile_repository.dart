import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile_model.dart';

class UserProfileRepository {
  static const String _nameKey = 'user_profile_name';
  static const String _phoneKey = 'user_profile_phone';
  static const String _upiIdKey = 'user_profile_upi_id';

  Future<UserProfileModel> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfileModel(
      name: prefs.getString(_nameKey)?.trim() ?? '',
      phone: _emptyToNull(prefs.getString(_phoneKey)),
      upiId: _emptyToNull(prefs.getString(_upiIdKey)),
    );
  }

  Future<void> saveProfile(UserProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, profile.name.trim());

    final phone = profile.phone?.trim() ?? '';
    if (phone.isEmpty) {
      await prefs.remove(_phoneKey);
    } else {
      await prefs.setString(_phoneKey, phone);
    }

    final upiId = profile.upiId?.trim() ?? '';
    if (upiId.isEmpty) {
      await prefs.remove(_upiIdKey);
    } else {
      await prefs.setString(_upiIdKey, upiId);
    }
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
