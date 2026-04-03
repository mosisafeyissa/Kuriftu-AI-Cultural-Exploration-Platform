class User {
  final int id;
  final String email;
  final String fullName;
  final String phone;
  final DateTime dateJoined;

  const User({
    required this.id,
    required this.email,
    this.fullName = '',
    this.phone = '',
    required this.dateJoined,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      dateJoined: DateTime.parse(json['date_joined'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'date_joined': dateJoined.toIso8601String(),
      };
}
