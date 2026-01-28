/// Habit model
class Habit {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;

  Habit({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'is_active': isActive,
      'created_by': createdBy,
    };
  }
}

/// Habit Assignment model
class HabitAssignment {
  final String id;
  final String protegeId;
  final String habitId;
  final List<String> repetitionDays;
  final DateTime? assignedAt;
  final Habit? habit;

  HabitAssignment({
    required this.id,
    required this.protegeId,
    required this.habitId,
    required this.repetitionDays,
    this.assignedAt,
    this.habit,
  });

  factory HabitAssignment.fromJson(Map<String, dynamic> json) {
    return HabitAssignment(
      id: json['id'] as String,
      protegeId: json['protege_id'] as String,
      habitId: json['habit_id'] as String,
      repetitionDays: List<String>.from(json['repetition_days'] ?? []),
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
      habit: json['habits'] != null ? Habit.fromJson(json['habits']) : null,
    );
  }
}

/// Habit Log model
class HabitLog {
  final String id;
  final String habitId;
  final String protegeId;
  final DateTime date;
  final String? startTime;
  final int? durationMinutes;
  final String? beforeFeeling;
  final String? afterFeeling;
  final String? notes;
  final String verificationStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNotes;
  final DateTime? createdAt;
  final Habit? habit;
  final String? protegeName;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.protegeId,
    required this.date,
    this.startTime,
    this.durationMinutes,
    this.beforeFeeling,
    this.afterFeeling,
    this.notes,
    this.verificationStatus = 'pending',
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNotes,
    this.createdAt,
    this.habit,
    this.protegeName,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      protegeId: json['protege_id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      beforeFeeling: json['before_feeling'] as String?,
      afterFeeling: json['after_feeling'] as String?,
      notes: json['notes'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      verificationNotes: json['verification_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      habit: json['habits'] != null ? Habit.fromJson(json['habits']) : null,
      protegeName: json['Users']?['Name'] as String?,
    );
  }

  bool get isPending => verificationStatus == 'pending';
  bool get isApproved => verificationStatus == 'approved';
  bool get isRejected => verificationStatus == 'rejected';
}

/// Habit Streak model
class HabitStreak {
  final String id;
  final String protegeId;
  final String habitId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLoggedDate;
  final DateTime? updatedAt;

  HabitStreak({
    required this.id,
    required this.protegeId,
    required this.habitId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLoggedDate,
    this.updatedAt,
  });

  factory HabitStreak.fromJson(Map<String, dynamic> json) {
    return HabitStreak(
      id: json['id'] as String,
      protegeId: json['protege_id'] as String,
      habitId: json['habit_id'] as String,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastLoggedDate: json['last_logged_date'] != null
          ? DateTime.parse(json['last_logged_date'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
