import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../auth/data/auth_provider.dart';
import '../habits/habit_providers.dart';
import '../habits/habit_log_screen.dart';

class ProtegeHomeScreen extends ConsumerStatefulWidget {
  const ProtegeHomeScreen({super.key});

  @override
  ConsumerState<ProtegeHomeScreen> createState() => _ProtegeHomeScreenState();
}

class _ProtegeHomeScreenState extends ConsumerState<ProtegeHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotifications();
    });
  }

  @override
  void dispose() {
    SupabaseService.disposeNotificationListeners();
    super.dispose();
  }

  Future<void> _setupNotifications() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await SupabaseService.initNotificationListeners(user.id);
      await SupabaseService.scheduleTaskDeadlineNotifications(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildHabitsTab(),
          _buildTasksTab(),
          _buildProgressTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.self_improvement, Icons.self_improvement, 'Habits'),
              _buildNavItem(2, Icons.task_alt_outlined, Icons.task_alt, 'Tasks'),
              _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart, 'Progress'),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final user = ref.watch(currentUserProvider);
    final habitsAsync = ref.watch(protegeHabitsProvider);
    final tasksAsync = ref.watch(protegeTasksProvider);
    final streakAsync = ref.watch(currentStreakProvider);
    final analyticsAsync = ref.watch(habitAnalyticsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(protegeHabitsProvider);
          ref.invalidate(protegeTasksProvider);
          ref.invalidate(currentStreakProvider);
          ref.invalidate(habitAnalyticsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting with dynamic streak
              _buildGreeting(user?.name ?? 'Seeker', streakAsync),
              const SizedBox(height: 24),
              
              // Stats cards
              _buildStatsSection(analyticsAsync),
              const SizedBox(height: 24),
              
              // Today's habits
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Practice",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              habitsAsync.when(
                data: (habits) {
                  if (habits.isEmpty) return _buildEmptyHabits();
                  return Column(
                    children: habits.take(3).map((a) => _buildHabitCard(a)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildErrorCard('Error loading habits: $e'),
              ),
              
              const SizedBox(height: 24),
              
              // Tasks section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Tasks',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) return _buildEmptyTasks();
                  return Column(
                    children: tasks.take(2).map((t) => _buildTaskCard(t)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildErrorCard('Error loading tasks: $e'),
              ),
              
              const SizedBox(height: 24),
              
              // Inspirational quote
              _buildQuoteCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }

  Widget _buildGreeting(String name, AsyncValue<int> streakAsync) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      icon = Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      icon = Icons.wb_sunny;
    } else {
      greeting = 'Good Evening';
      icon = Icons.nightlight_outlined;
    }

    final streak = streakAsync.valueOrNull ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Dynamic streak badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.secondaryDark],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Text(
                '$streak',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(AsyncValue<Map<String, dynamic>> analyticsAsync) {
    final analytics = analyticsAsync.valueOrNull ?? {};
    final totalLogs = analytics['total_logs'] ?? 0;
    final uniqueDays = analytics['unique_days'] ?? 0;
    final longestStreak = analytics['longest_streak'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            iconColor: AppColors.success,
            value: '$totalLogs',
            label: 'Logs',
            bgColor: AppColors.successLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            iconColor: AppColors.primary,
            value: '$uniqueDays',
            label: 'Active Days',
            bgColor: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.emoji_events,
            iconColor: AppColors.secondary,
            value: '$longestStreak',
            label: 'Best Streak',
            bgColor: AppColors.warningLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHabits() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.self_improvement,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No habits assigned yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your chaperone will assign practices soon',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTasks() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_alt_outlined,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No tasks assigned yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Map<String, dynamic> assignment) {
    final habit = assignment['habits'];
    final habitName = habit?['name'] ?? 'Practice';
    final habitDescription = habit?['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showHabitLogSheet(assignment),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habitName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (habitDescription.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          habitDescription,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Log',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> assignment) {
    final task = assignment['tasks'] ?? {};
    final title = task['name'] ?? 'Task';
    final description = task['description'] ?? '';
    final status = assignment['status'] ?? 'assigned';
    final deadline = task['deadline'];

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'verified':
        statusColor = AppColors.success;
        statusLabel = 'Done';
        break;
      case 'pending_verification':
        statusColor = AppColors.warning;
        statusLabel = 'Pending';
        break;
      default:
        statusColor = AppColors.primary;
        statusLabel = 'Assigned';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTaskDetails(assignment),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    status == 'verified' ? Icons.check_circle : Icons.task_alt,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (deadline != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Due: ${_formatDeadline(deadline)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDeadline(String? deadline) {
    if (deadline == null) return '';
    try {
      final date = DateTime.parse(deadline);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return deadline;
    }
  }

  void _showHabitLogSheet(Map<String, dynamic> assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HabitLogSheet(assignment: assignment),
    ).then((_) {
      // Refresh data after logging
      ref.invalidate(protegeHabitsProvider);
      ref.invalidate(currentStreakProvider);
      ref.invalidate(habitAnalyticsProvider);
    });
  }

  void _showTaskDetails(Map<String, dynamic> assignment) {
    final task = assignment['tasks'] ?? {};
    final title = task['name'] ?? 'Task';
    final description = task['description'] ?? '';
    final status = assignment['status'] ?? 'assigned';
    final deadline = task['deadline'];
    final assignmentId = assignment['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  
                  // Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  
                  if (deadline != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${_formatDeadline(deadline)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Status section
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  
                  if (status == 'verified')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success),
                          SizedBox(width: 8),
                          Text(
                            'Task Completed',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (status == 'pending_verification')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.hourglass_empty, color: AppColors.warning),
                          SizedBox(width: 8),
                          Text(
                            'Awaiting verification',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await SupabaseService.updateTaskStatus(
                              assignmentId: assignmentId,
                              status: 'pending_verification',
                            );
                            ref.invalidate(protegeTasksProvider);
                            if (context.mounted) Navigator.pop(context);
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Task marked as complete!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Mark as Complete'),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote, color: Colors.white54, size: 32),
          const SizedBox(height: 8),
          const Text(
            'What heights could we reach if we became truly systematic in our practice—daily, consciously, joyfully?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '— Daaji',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsTab() {
    final habitsAsync = ref.watch(protegeHabitsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(protegeHabitsProvider),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Habits',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your daily spiritual practices',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: habitsAsync.when(
                  data: (habits) {
                    if (habits.isEmpty) return Center(child: _buildEmptyHabits());
                    return ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) => _buildHabitCard(habits[index]),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: _buildErrorCard('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    final tasksAsync = ref.watch(protegeTasksProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(protegeTasksProvider),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Tasks',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tasks assigned by your chaperone',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) {
                    if (tasks.isEmpty) return Center(child: _buildEmptyTasks());
                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: _buildErrorCard('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    final analyticsAsync = ref.watch(habitAnalyticsProvider);
    final weeklyDataAsync = ref.watch(weeklyChartDataProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(habitAnalyticsProvider);
          ref.invalidate(weeklyChartDataProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Progress',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your spiritual journey',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Stats from analytics
              analyticsAsync.when(
                data: (analytics) {
                  final totalLogs = analytics['total_logs'] ?? 0;
                  final uniqueDays = analytics['unique_days'] ?? 0;
                  final uniqueHabits = analytics['unique_habits'] ?? 0;
                  final currentStreak = analytics['current_streak'] ?? 0;
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildProgressCard(
                              'Total Logs',
                              '$totalLogs',
                              Icons.list_alt,
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildProgressCard(
                              'Active Days',
                              '$uniqueDays',
                              Icons.calendar_today,
                              AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProgressCard(
                              'Habits Tracked',
                              '$uniqueHabits',
                              Icons.self_improvement,
                              AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildProgressCard(
                              'Current Streak',
                              '$currentStreak',
                              Icons.local_fire_department,
                              AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildErrorCard('Error: $e'),
              ),
              
              const SizedBox(height: 24),
              
              // Weekly chart
              Text(
                'This Week',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              weeklyDataAsync.when(
                data: (weekData) => _buildWeeklyChart(weekData),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildErrorCard('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<Map<String, dynamic>> weekData) {
    final maxCount = weekData.fold<int>(1, (max, day) {
      final count = day['count'] as int;
      return count > max ? count : max;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Bar chart
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.map((day) {
                final count = day['count'] as int;
                final dayName = day['day'] as String;
                final heightPercent = count / maxCount;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 32,
                      height: 100 * heightPercent + 10,
                      decoration: BoxDecoration(
                        color: count > 0 ? AppColors.primary : AppColors.divider,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final user = ref.watch(currentUserProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Profile avatar
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              user?.name ?? 'User',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Protégé',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Menu items
            _buildMenuItem(
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              label: 'Help & Support',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.info_outline,
              label: 'About LAMP',
              onTap: () {},
            ),
            
            const SizedBox(height: 16),
            
            // Logout button
            TextButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
