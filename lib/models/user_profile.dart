class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.status,
    required this.role,
    this.phone,
    this.address,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as int,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    username: json['username'] as String,
    status: json['status'] as String,
    role: json['role'] as String? ?? 'customer',
    phone: json['phone'] as String?,
    address: json['address'] as String?,
  );

  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String status;
  final String role;
  final String? phone;
  final String? address;
  String get fullName => '$firstName $lastName'.trim();
  bool get isActive => status == 'active';
  bool get isAdmin => role == 'admin';
}
