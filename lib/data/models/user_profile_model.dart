class UserProfileModel {
  final String name;
  final String? phone;
  final String? upiId;

  const UserProfileModel({required this.name, this.phone, this.upiId});

  bool get hasName => name.trim().isNotEmpty;

  UserProfileModel copyWith({String? name, String? phone, String? upiId}) {
    return UserProfileModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      upiId: upiId ?? this.upiId,
    );
  }
}
