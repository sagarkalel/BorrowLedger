class UserProfileModel {
  final String name;
  final String? phone;

  const UserProfileModel({required this.name, this.phone});

  bool get hasName => name.trim().isNotEmpty;

  UserProfileModel copyWith({String? name, String? phone}) {
    return UserProfileModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }
}
