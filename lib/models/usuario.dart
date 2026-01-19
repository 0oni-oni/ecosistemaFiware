class Usuario {
  final int id;
  final String username;
  final String role;

  Usuario({required this.id, required this.username, required this.role});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'role': role};
  }

  bool get isAdmin => role == 'admin' || role == 'root';
}
