class UserModel {
  final String? id;
  final String mobile;
  final String role;
  final String? name;
  final String? email;
  final String? city;
  final String? photoUrl;
  final bool isActive;

  const UserModel({
    this.id,
    required this.mobile,
    required this.role,
    this.name,
    this.email,
    this.city,
    this.photoUrl,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      mobile: json['mobile']?.toString() ?? '',
      role: json['role']?.toString() ?? 'CUSTOMER',
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      city: json['city']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobile': mobile,
      'role': role,
      'name': name,
      'email': email,
      'city': city,
      'photo_url': photoUrl,
      'is_active': isActive,
    };
  }
}
