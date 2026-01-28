import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../auth/data/auth_provider.dart';

/// Habit log bottom sheet
class HabitLogSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> assignment;

  const HabitLogSheet({super.key, required this.assignment});

  @override
  ConsumerState<HabitLogSheet> createState() => _HabitLogSheetState();
}

class _HabitLogSheetState extends ConsumerState<HabitLogSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _durationMinutes;
  String? _beforeFeeling;
  String? _afterFeeling;
  String? _notes;
  bool _isLoading = false;

  final List<String> _feelings = [
    '😔 Low',
    '😐 Neutral',
    '🙂 Good',
    '😊 Great',
    '🌟 Amazing',
  ];

  @override
  Widget build(BuildContext context) {
    final habit = widget.assignment['habits'] ?? {};
    final habitName = habit['name'] ?? 'Practice';
    final habitDescription = habit['description'] ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.self_improvement,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habitName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (habitDescription.isNotEmpty)
                            Text(
                              habitDescription,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Duration
                Text(
                  'Duration (minutes)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [5, 10, 15, 20, 30, 45, 60].map((mins) {
                    final isSelected = _durationMinutes == mins;
                    return ChoiceChip(
                      label: Text('$mins'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _durationMinutes = selected ? mins : null);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Before feeling
                Text(
                  'How did you feel before?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _feelings.map((feeling) {
                    final isSelected = _beforeFeeling == feeling;
                    return ChoiceChip(
                      label: Text(feeling),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _beforeFeeling = selected ? feeling : null);
                      },
                      selectedColor: AppColors.secondary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // After feeling
                Text(
                  'How do you feel after?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _feelings.map((feeling) {
                    final isSelected = _afterFeeling == feeling;
                    return ChoiceChip(
                      label: Text(feeling),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _afterFeeling = selected ? feeling : null);
                      },
                      selectedColor: AppColors.success,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Notes
                Text(
                  'Notes (optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _notes = value,
                ),

                const SizedBox(height: 32),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitLog,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle),
                            SizedBox(width: 8),
                            Text('Log Practice'),
                          ],
                        ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitLog() async {
    if (_durationMinutes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a duration'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      // Get habit ID from the assignment
      final habitId = widget.assignment['habit_id'] ?? 
                      widget.assignment['habits']?['id'];
      
      if (habitId == null) throw Exception('Habit ID not found');

      await SupabaseService.logHabit(
        habitId: habitId,
        protegeId: user.id,
        date: DateTime.now(),
        durationMinutes: _durationMinutes,
        beforeFeeling: _beforeFeeling,
        afterFeeling: _afterFeeling,
        notes: _notes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Practice logged successfully! 🎉'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
