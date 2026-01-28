import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../auth/data/auth_provider.dart';
import '../proteges/chaperone_providers.dart';

class AssignTaskSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> task;

  const AssignTaskSheet({super.key, required this.task});

  @override
  ConsumerState<AssignTaskSheet> createState() => _AssignTaskSheetState();
}

class _AssignTaskSheetState extends ConsumerState<AssignTaskSheet> {
  final Set<String> _selectedProteges = {};
  DateTime? _dueDate;
  bool _isLoading = false;

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _assignTask() async {
    if (_selectedProteges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one protégé'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      
      final taskId = widget.task['id'] as String;
      
      for (final protegeId in _selectedProteges) {
        await SupabaseService.assignTask(
          taskId: taskId,
          protegeId: protegeId,
          assignedBy: user.id,
        );
      }
      
      ref.invalidate(taskAssignmentsProvider);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task assigned to ${_selectedProteges.length} protégé(s)'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  @override
  Widget build(BuildContext context) {
    final protegesAsync = ref.watch(assignedProtegesProvider);
    final taskTitle = widget.task['name'] ?? 'Task';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
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
                Text(
                  'Assign Task',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  taskTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Due date selector
                GestureDetector(
                  onTap: _selectDueDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          _dueDate != null
                              ? 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                              : 'Set due date (optional)',
                          style: TextStyle(
                            color: _dueDate != null 
                                ? AppColors.textPrimary 
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Select Protégés',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                
                const SizedBox(height: 12),
                
                // Protégé list
                Expanded(
                  child: protegesAsync.when(
                    data: (proteges) {
                      if (proteges.isEmpty) {
                        return const Center(
                          child: Text('No protégés assigned to you'),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: proteges.length,
                        itemBuilder: (context, index) {
                          final protege = proteges[index];
                          final user = protege['Users'] ?? protege;
                          final protegeId = protege['protege_id'] ?? user['id'];
                          final name = user['Name'] ?? 'Protégé';
                          final isSelected = _selectedProteges.contains(protegeId);
                          
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedProteges.add(protegeId);
                                } else {
                                  _selectedProteges.remove(protegeId);
                                }
                              });
                            },
                            title: Text(name),
                            secondary: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Assign button
                ElevatedButton(
                  onPressed: _isLoading ? null : _assignTask,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Assign to ${_selectedProteges.length} Protégé(s)'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
