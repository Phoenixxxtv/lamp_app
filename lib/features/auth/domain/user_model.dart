/// User model for the LAMP app
class LampUser {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String role;
  final String? gender;
  final int? age;
  final String? chaperoneId;
  final int? batchNo;
  final int? currentStreak;
  final String? location;
  final String? language;
  final String? hfnId;
  final DateTime? createdAt;

  LampUser({
    required this.id,
    this.name,
    this.email,
    this.phone,
    required this.role,
    this.gender,
    this.age,
    this.chaperoneId,
    this.batchNo,
    this.currentStreak,
    this.location,
    this.language,
    this.hfnId,
    this.createdAt,
  });

  factory LampUser.fromJson(Map<String, dynamic> json) {
    return LampUser(
      id: json['id'] as String,
      name: json['Name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'protege',
      gender: json['Gender'] as String?,
      age: json['Age'] as int?,
      chaperoneId: json['chaperone_id'] as String?,
      batchNo: json['batchNo'] as int?,
      currentStreak: json['currentStreak'] as int?,
      location: json['location'] as String?,
      language: json['language'] as String?,
      hfnId: json['HFN_ID'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'Gender': gender,
      'Age': age,
      'chaperone_id': chaperoneId,
      'batchNo': batchNo,
      'currentStreak': currentStreak,
      'location': location,
      'language': language,
      'HFN_ID': hfnId,
    };
  }

  bool get isProtege => role == 'protege';
  bool get isChaperone => role == 'chaperone';
  bool get isAdmin => role == 'admin';

  LampUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? gender,
    int? age,
    String? chaperoneId,
    int? batchNo,
    int? currentStreak,
    String? location,
    String? language,
    String? hfnId,
    DateTime? createdAt,
  }) {
    return LampUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      chaperoneId: chaperoneId ?? this.chaperoneId,
      batchNo: batchNo ?? this.batchNo,
      currentStreak: currentStreak ?? this.currentStreak,
      location: location ?? this.location,
      language: language ?? this.language,
      hfnId: hfnId ?? this.hfnId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
