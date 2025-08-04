class User {
  final String token;
  final String email;
  final String fullname;
  final String role;
  final String roleId;
  final String expiration;

  User({
    required this.token,
    required this.email,
    required this.fullname,
    required this.role,
    required this.roleId,
    required this.expiration,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      token: json['token'],
      email: json['email'],
      fullname: json['fullname'],
      role: json['role'],
      roleId: json['roleId'].toString(),
      expiration: json['expiration'],
    );
  }
}