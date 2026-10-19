import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/habit_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTimer;
  final VoidCallback? onNavigateToExercises;
  final VoidCallback? onLogout;

  const DashboardScreen({
    super.key,
    this.onNavigateToTimer,
    this.onNavigateToExercises,
    this.onLogout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const platform = MethodChannel('com.alignx/notifications');
  Map<String, dynamic> analyticsData = {};
  List<Habit> habitList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    final activeUser = AuthService.currentUser;
    final userId = activeUser?.id ?? "user-dhanesh";
    final analytics = await ApiService.fetchAnalytics();
    final habits = await ApiService.fetchUserHabits(userId);

    if (mounted) {
      setState(() {
        analyticsData = analytics;
        habitList = habits;
        isLoading = false;
      });
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF6B88)),
            SizedBox(width: 10),
            Text(
              'Log Out of AlignX',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out? Your posture streaks and daily habits will remain safely saved in the cloud.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B88),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (mounted) {
                widget.onLogout?.call();
              }
            },
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Native MethodChannel Trigger
  Future<void> _triggerNativePostureAlert() async {
    try {
      final String? result = await platform.invokeMethod('showPostureReminder');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(result ?? "Native posture reminder sent!"),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to invoke native alert: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFFF6B88),
            content: Text("⚠️ AlignX Posture Check: Sit up straight and align your spine!"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleHabit(Habit habit) async {
    final newStatus = !habit.completedToday;
    setState(() {
      habit.completedToday = newStatus;
      if (newStatus) {
        habit.currentStreak += 1;
      } else if (habit.currentStreak > 0) {
        habit.currentStreak -= 1;
      }
    });

    await ApiService.toggleHabitCompletion(habit.id, newStatus);
  }

  void _showAddHabitDialog() {
    final titleController = TextEditingController();
    String category = 'Posture';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: const Text('Add Daily Habit', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  labelText: 'Habit Title',
                  labelStyle: TextStyle(color: Color(0xFF64748B)),
                  hintText: 'e.g. Chin tucks at desk',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF0F172A)),
                items: const [
                  DropdownMenuItem(value: 'Posture', child: Text('Posture')),
                  DropdownMenuItem(value: 'APT Alignment', child: Text('APT Alignment')),
                  DropdownMenuItem(value: 'Hydration', child: Text('Hydration')),
                  DropdownMenuItem(value: 'Movement', child: Text('Movement')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => category = val);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  final newHabit = Habit(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: 'user-dhanesh',
                    title: title,
                    category: category,
                    currentStreak: 0,
                    completedToday: false,
                  );
                  setState(() {
                    habitList.insert(0, newHabit);
                  });
                  Navigator.pop(ctx);
                  await ApiService.createHabit(newHabit);
                }
              },
              child: const Text('Add Habit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postureScoreRaw = analyticsData['postureScore']?.toString() ?? '78%';
    final posturePercent = (double.tryParse(postureScoreRaw.replaceAll('%', '')) ?? 78.0) / 100.0;
    final activeUser = AuthService.currentUser;
    final userName = activeUser?.name ?? analyticsData['user'] ?? 'Dhanesh Kumbharkar';
    final sittingTime = analyticsData['dailySittingTime'] ?? '2h 34m';
    final alertsCount = analyticsData['postureAlertsCount']?.toString() ?? '2';
    final streak = analyticsData['currentStreak']?.toString() ?? '7';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.accessibility_new, color: Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'AlignX',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Trigger Native Posture Alert',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B88).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: Color(0xFFFF6B88), size: 20),
            ),
            onPressed: _triggerNativePostureAlert,
          ),
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
            onPressed: _loadAllData,
          ),
          IconButton(
            tooltip: 'Log Out',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B88).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B88), size: 18),
            ),
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF6366F1),
              backgroundColor: Colors.white,
              onRefresh: _loadAllData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Welcome Header
                  Text(
                    "Good Morning, $userName ☀️",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Small changes make a big difference for your spine!",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 18),

                  // Main Posture Score Card with Percent Indicator
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF8FAFC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircularPercentIndicator(
                          radius: 46.0,
                          lineWidth: 9.0,
                          animation: true,
                          percent: posturePercent.clamp(0.0, 1.0),
                          center: Text(
                            postureScoreRaw,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          circularStrokeCap: CircularStrokeCap.round,
                          progressColor: const Color(0xFF10B981),
                          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Daily Posture Health",
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                posturePercent >= 0.75
                                     ? "Great job! Optimal spinal curvature maintained."
                                     : "Warning: Slouching detected during prolonged sitting.",
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _triggerNativePostureAlert,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Send Spine Check Alert",
                                      style: TextStyle(
                                        color: Color(0xFFFF6B88),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFFFF6B88)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Analytics Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Sitting Time",
                          value: sittingTime,
                          color: const Color(0xFF6366F1),
                          icon: Icons.chair_alt,
                          caption: "Healthy target < 4h",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          title: "Habit Streak",
                          value: "$streak Days",
                          color: const Color(0xFF10B981),
                          icon: Icons.local_fire_department,
                          caption: "Keep it up!",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          title: "Slouch Alerts",
                          value: alertsCount,
                          color: const Color(0xFFFF6B88),
                          icon: Icons.warning_amber_rounded,
                          caption: "Today",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Quick Action Banners
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          title: "Posture Timer",
                          subtitle: "25m Interval",
                          icon: Icons.timer_outlined,
                          accentColor: const Color(0xFF6366F1),
                          onTap: widget.onNavigateToTimer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickActionCard(
                          title: "APT Stretches",
                          subtitle: "5 Core Exercises",
                          icon: Icons.fitness_center_outlined,
                          accentColor: const Color(0xFF10B981),
                          onTap: widget.onNavigateToExercises,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Today's Focus Checklist Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Focus Checklist",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add Custom Habit',
                        icon: const Icon(Icons.add_circle, color: Color(0xFF6366F1)),
                        onPressed: _showAddHabitDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Habit List
                  if (habitList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: const Text(
                        "No habits found. Add your first posture habit above!",
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  else
                    ...habitList.map((habit) => _buildHabitCard(habit)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required String caption,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final isDone = habit.completedToday;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: IconButton(
          icon: Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
            size: 26,
          ),
          onPressed: () => _toggleHabit(habit),
        ),
        title: Text(
          habit.title,
          style: TextStyle(
            color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                habit.category,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "🔥 ${habit.currentStreak} Days Streak",
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
        trailing: isDone
            ? const Icon(Icons.done_all, color: Color(0xFF10B981), size: 18)
            : null,
        onTap: () => _toggleHabit(habit),
      ),
    );
  }
}
