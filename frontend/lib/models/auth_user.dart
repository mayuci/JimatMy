class AuthUser {
  const AuthUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.avatarType = 'initial',
    this.avatarValue,
  });

  final String userId;
  final String name;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String avatarType;
  final String? avatarValue;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    userId: json['userId'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    avatarType: _avatarType(json['avatarType']),
    avatarValue: json['avatarValue'] as String?,
  );

  static String _avatarType(Object? value) =>
      value == 'preset' || value == 'upload' ? value! as String : 'initial';
}

class AuthSession {
  const AuthSession({required this.token, required this.user});
  final String token;
  final AuthUser user;
}
