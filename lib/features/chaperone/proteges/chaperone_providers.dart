import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_provider.dart';
import '../../../services/supabase_service.dart';

/// Provider for chaperone's assigned proteges
final assignedProtegesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return await SupabaseService.getAssignedProteges(user.id);
});

/// Provider for tasks created by chaperone
final chaperoneTasksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return await SupabaseService.getTasksCreatedBy(user.id);
});

/// Provider for all task assignments for chaperone's proteges
final taskAssignmentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return await SupabaseService.getChaperoneTaskAssignments(user.id);
});

/// Provider for all habits
final allHabitsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await SupabaseService.getAllHabits();
});
