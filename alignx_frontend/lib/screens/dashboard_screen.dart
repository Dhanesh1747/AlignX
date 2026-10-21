import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/habit_model.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final Future<void> Function() onLogout;
  final VoidCallback? onNavigateToTimer;
  final VoidCallback? onNavigateToExercises;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.onLogout,
    this.onNavigateToTimer,
    this.onNavigateToExercises,
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
    final analytics = await ApiService.fetchAnalytics();
    final habits = await ApiService.fetchUserHabits(widget.userId);

    if (mounted) {
      setState(() {
        analyticsData = analytics;
        habitList = habits;
        isLoading = false;
      });
    }
  }

  // Native MethodChannel Trigger
  Future<void> _triggerNativePostureAlert() async {
    try {
      final String? result = await platform.invokeMethod('showPostureReminder');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          SnackBar(
            backgroundColor: const Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text("⚠️ AlignX Posture Check: Sit up straight and align your spine!"),
            duration: const Duration(seconds: 2),
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
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    borderSide: BorderSide(color: Color(0xFF4F46E5)),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  final newHabit = Habit(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: widget.userId,
                    title: title,
                    category: category,
                    currentStreak: 0,
                    completedToday: false,
                  );
                  setState(() {
                    habitList.insert(0, newHabit);
                  });
                  Navigator.pop(dialogContext);
                  final savedHabit = await ApiService.createHabit(newHabit);
                  if (savedHabit != null && mounted) {
                    setState(() {
                      final index = habitList.indexWhere((habit) => habit.id == newHabit.id);
                      if (index != -1) habitList[index] = savedHabit;
                    });
                  } else if (mounted) {
                    setState(() => habitList.removeWhere((habit) => habit.id == newHabit.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not save this habit. Please try again.')),
                    );
                  }
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
    final postureScoreRaw = analyticsData['postureScore']?.toString() ?? '--';
    final postureValue = double.tryParse(postureScoreRaw.replaceAll('%', ''));
    final posturePercent = postureValue == null ? 0.0 : postureValue / 100.0;
    final userName = widget.userName;
    final sittingTime = analyticsData['dailySittingTime']?.toString() ?? '--';
    final alertsCount = analyticsData['postureAlertsCount']?.toString() ?? '0';
    final streak = analyticsData['currentStreak']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.accessibility_new, color: Color(0xFF4F46E5), size: 22),
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
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: Color(0xFFE11D48), size: 20),
            ),
            onPressed: _triggerNativePostureAlert,
          ),
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
            onPressed: _loadAllData,
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
            onPressed: widget.onLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF4F46E5),
              backgroundColor: Colors.white,
              onRefresh: _loadAllData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Welcome Header
                  Text(
                    "Good Morning, $userName ☀️",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Small changes make a big difference for your spine!",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Posture Health Section with Image (Responsive matching height & width)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const double cardHeight = 240.0;
                      if (constraints.maxWidth >= 720) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildPostureStatsBox(
                                posturePercent: posturePercent,
                                postureScoreRaw: postureScoreRaw,
                                height: cardHeight,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPostureImageBox(height: cardHeight),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildPostureStatsBox(
                              posturePercent: posturePercent,
                              postureScoreRaw: postureScoreRaw,
                              height: cardHeight,
                            ),
                            const SizedBox(height: 14),
                            _buildPostureImageBox(height: cardHeight),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Analytics Cards Grid (With Smartwatch in Sitting Time)
                  Row(
                    children: [
                      // Sitting Time with Smartwatch Widget
                      Expanded(
                        child: _buildSittingTimeCard(sittingTime: sittingTime),
                      ),
                      const SizedBox(width: 12),
                      // Habit Streak Card
                      Expanded(
                        child: _buildStatCard(
                          title: "Habit Streak",
                          value: "$streak Days",
                          color: const Color(0xFF059669),
                          icon: Icons.local_fire_department,
                          iconBg: const Color(0xFFD1FAE5),
                          caption: "Consistent posture",
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Slouch Alerts Card
                      Expanded(
                        child: _buildStatCard(
                          title: "Slouch Alerts",
                          value: alertsCount,
                          color: const Color(0xFFE11D48),
                          icon: Icons.warning_amber_rounded,
                          iconBg: const Color(0xFFFFE4E6),
                          caption: "Triggered today",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Quick Action Banners
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          title: "Posture Timer",
                          subtitle: "25m Interval Alert",
                          icon: Icons.timer_outlined,
                          accentColor: const Color(0xFF4F46E5),
                          bgColor: const Color(0xFFEEF2FF),
                          onTap: widget.onNavigateToTimer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildQuickActionCard(
                          title: "APT Stretches",
                          subtitle: "5 Corrective Exercises",
                          icon: Icons.fitness_center_outlined,
                          accentColor: const Color(0xFF059669),
                          bgColor: const Color(0xFFD1FAE5),
                          onTap: widget.onNavigateToExercises,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // Today's Focus Checklist Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Focus Checklist",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text("Add Habit", style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: _showAddHabitDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Habit List
                  if (habitList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
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

  // Posture Health Stats Box (Box 1)
  Widget _buildPostureStatsBox({
    required double posturePercent,
    required String postureScoreRaw,
    required double height,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 52.0,
            lineWidth: 10.0,
            animation: true,
            percent: posturePercent.clamp(0.0, 1.0),
            center: Text(
              postureScoreRaw,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF059669),
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: const Color(0xFF059669),
            backgroundColor: const Color(0xFFD1FAE5),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Daily Posture Health",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                    postureScoreRaw == '--'
                        ? "Posture measurements are not connected yet."
                        : posturePercent >= 0.75
                            ? "Great job! Optimal spinal curvature and alignment maintained."
                            : "Warning: Slouching detected during prolonged sitting.",
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _triggerNativePostureAlert,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.vibration, size: 14, color: Color(0xFFE11D48)),
                        SizedBox(width: 6),
                        Text(
                          "Send Spine Check Alert",
                          style: TextStyle(
                            color: Color(0xFFE11D48),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFE11D48)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Posture Slouch Image Box (Box 2 - with matching height & width)
  Widget _buildPostureImageBox({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F1D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ambient matching blurred background with low opacity
            Opacity(
              opacity: 0.3,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Image.asset(
                  'assets/images/posture_slouch.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            // Semi-dark ambient tint
            Container(
              color: const Color(0xFF0C0F1D).withValues(alpha: 0.45),
            ),
            // The FULL, UNCROPPED posture illustration with low opacity
            Center(
              child: Opacity(
                opacity: 0.65,
                child: Image.asset(
                  'assets/images/posture_slouch.jpg',
                  fit: BoxFit.contain,
                  height: height,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFEEF2FF),
                    child: const Center(
                      child: Icon(Icons.accessibility_new, size: 48, color: Color(0xFF4F46E5)),
                    ),
                  ),
                ),
              ),
            ),
            // Floating Status Pill Overlay
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFFF6B88)),
                    SizedBox(width: 5),
                    Text(
                      "Spine Angle Monitor",
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Caption
            const Positioned(
              bottom: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Slouch Angle Detected",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Sit Straight",
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sitting Time Card with Embedded Smartwatch
  Widget _buildSittingTimeCard({required String sittingTime}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              const Text(
                "Sitting Time",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.watch_later_outlined, color: Color(0xFF4F46E5), size: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Stylish Smartwatch Widget
              _buildSmartwatchWidget(timeText: sittingTime),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sittingTime,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Target < 4h",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Custom Smartwatch Visual
  Widget _buildSmartwatchWidget({required String timeText}) {
    return SizedBox(
      width: 44,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top Strap
          Positioned(
            top: 0,
            child: Container(
              width: 18,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF334155),
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
          ),
          // Bottom Strap
          Positioned(
            bottom: 0,
            child: Container(
              width: 18,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF334155),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
            ),
          ),
          // Watch Case / Bezel
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFF64748B), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              // Watch Dial Face
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4F46E5), width: 1),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_walk, size: 9, color: Color(0xFF10B981)),
                    SizedBox(height: 1),
                    Text(
                      "LIVE",
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Watch Side Crown Button
          Positioned(
            right: 0,
            child: Container(
              width: 2.5,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF94A3B8),
                borderRadius: BorderRadius.horizontal(right: Radius.circular(1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Generic Stat Card
  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Color iconBg,
    required IconData icon,
    required String caption,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // Quick Action Card
  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // Habit Card
  Widget _buildHabitCard(Habit habit) {
    final isDone = habit.completedToday;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? const Color(0xFFD1FAE5) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: IconButton(
          icon: Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? const Color(0xFF059669) : const Color(0xFF94A3B8),
            size: 26,
          ),
          onPressed: () => _toggleHabit(habit),
        ),
        title: Text(
          habit.title,
          style: TextStyle(
            color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 15,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  habit.category,
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "🔥 ${habit.currentStreak} Days Streak",
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: isDone
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.done, color: Color(0xFF059669), size: 16),
              )
            : null,
        onTap: () => _toggleHabit(habit),
      ),
    );
  }
}
