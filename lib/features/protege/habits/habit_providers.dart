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

/// Provider for today's habit logs (to check which habits are already logged)
final todayHabitLogsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  
  final logs = await SupabaseService.getHabitLogs(
    protegeId: user.id,
    limit: 50,
  );
  
  final today = DateTime.now().toIso8601String().split('T')[0];
  final loggedHabitIds = <String>{};
  
  for (final log in logs) {
    final logDate = log['date']?.toString() ?? '';
    // Handle both full ISO and date-only formats
    final datePart = logDate.contains('T') ? logDate.split('T')[0] : logDate;
    if (datePart == today) {
      final habitId = log['habit_id']?.toString();
      if (habitId != null) {
        loggedHabitIds.add(habitId);
      }
    }
  }
  
  return loggedHabitIds;
});

/// Provider for task completion statistics
final taskStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {'total': 0, 'completed': 0, 'pending': 0};
  
  final tasks = await SupabaseService.getAssignedTasks(user.id);
  
  int completed = 0;
  int pending = 0;
  
  for (final task in tasks) {
    final status = task['status'] ?? 'assigned';
    if (status == 'verified') {
      completed++;
    } else {
      pending++;
    }
  }
  
  return {
    'total': tasks.length,
    'completed': completed,
    'pending': pending,
  };
});
