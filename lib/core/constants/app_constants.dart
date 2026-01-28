/// Supabase Configuration
/// Replace these with your actual Supabase credentials
class SupabaseConfig {
  SupabaseConfig._();

  // Supabase project URL
  static const String supabaseUrl = 'https://gmrqcoisfoghljwqiuys.supabase.co';
  
  // Supabase anon key
  static const String supabaseAnonKey = 'sb_publishable_32HScVBfGlv4rNKr8kx-1A_dOyIPLEV';
}

/// App Configuration
class AppConfig {
  AppConfig._();

  static const String appName = 'LAMP';
  static const String appFullName = 'Limitless Advancement Mentoring Program';
  static const String appTagline = 'Regularise • Organise • Interiorise';
  static const String organizationName = 'Heartfulness';
}

/// User Roles
class UserRole {
  UserRole._();

  static const String protege = 'protege';
  static const String chaperone = 'chaperone';
  static const String admin = 'admin';
}

/// Habit Verification Status
class VerificationStatus {
  VerificationStatus._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

/// Task Assignment Status
class TaskStatus {
  TaskStatus._();

  static const String assigned = 'assigned';
  static const String toVerify = 'ToVerify';
  static const String verified = 'verified';
}
