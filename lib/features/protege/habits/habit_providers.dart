import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_provider.dart';
import '../../../services/supabase_service.dart';

/// Provider for protege's assigned habits
final protegeHabitsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return await SupabaseService.getAssignedHabits(user.id);
});

/// Provider for protege's assigned tasks
final protegeTasksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return await SupabaseService.getAssignedTasks(user.id);
});

/// Provider for protege's habit streaks
final protegeStreaksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return await SupabaseService.getHabitStreaks(user.id);
});

/// Provider for current total streak
final currentStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  
  return await SupabaseService.getTotalCurrentStreak(user.id);
});

/// Provider for protege's habit logs
final protegeHabitLogsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, habitId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return await SupabaseService.getHabitLogs(
    protegeId: user.id,
    habitId: habitId,
    limit: 20,
  );
});

/// Provider for habit analytics
final habitAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  
  return await SupabaseService.getHabitAnalytics(protegeId: user.id);
});

/// Provider for weekly chart data
final weeklyChartDataProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return await SupabaseService.getWeeklyHabitData(user.id);
});

/// Provider for protege home summary
final protegeSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  return await SupabaseService.getProtegeSummary(user.id);
});
