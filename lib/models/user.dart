/// Kullanıcıyı temsil eden veri modeli.
/// Swagger (case_study_server v1) API yapısına tamamen uyumludur.
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? profileImageUrl;
  final String? createdAt;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.profileImageUrl,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl ?? '',
    };
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
