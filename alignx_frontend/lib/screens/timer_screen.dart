import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const platform = MethodChannel('com.alignx/notifications');

  int totalSeconds = 25 * 60; // Default 25 min
  int remainingSeconds = 25 * 60;
  Timer? _timer;
  bool isRunning = false;
  bool fiveMinuteAlertsEnabled = true;
  String currentPreset = "25m Focus";

  final List<Map<String, dynamic>> presets = [
    {"label": "25m Focus", "seconds": 25 * 60, "desc": "Posture Pomodoro"},
    {"label": "45m Stand", "seconds": 45 * 60, "desc": "Sitting Limit"},
    {"label": "5m Reset", "seconds": 5 * 60, "desc": "Spinal Stretch"},
  ];

  final List<String> postureTips = [
    "Keep monitor at eye level to prevent forward head tilt.",
    "Elbows at 90° angle, resting lightly on desk or armrests.",
    "Sit with feet flat on the floor; don't cross legs.",
    "Tuck pelvis neutrally to avoid anterior pelvic compression.",
    "Relax your shoulders away from your ears.",
    "Breathe deeply into diaphragm rather than shallow chest breathing.",
  ];

  int currentTipIndex = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectPreset(String label, int seconds) {
    _timer?.cancel();
    setState(() {
      currentPreset = label;
      totalSeconds = seconds;
      remainingSeconds = seconds;
      isRunning = false;
    });
  }

  void _startTimer() {
    if (remainingSeconds <= 0) {
      remainingSeconds = totalSeconds;
    }
    setState(() => isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
          if (remainingSeconds % 120 == 0) {
            // Rotate posture tip every 2 minutes
            currentTipIndex = (currentTipIndex + 1) % postureTips.length;
          }
        });
        if (fiveMinuteAlertsEnabled &&
            remainingSeconds > 0 &&
            remainingSeconds % (5 * 60) == 0) {
          _showFiveMinuteAlert();
        }
      } else {
        _timer?.cancel();
        setState(() => isRunning = false);
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      remainingSeconds = totalSeconds;
      isRunning = false;
    });
  }

  Future<void> _onTimerComplete() async {
    try {
      await platform.invokeMethod('showPostureReminder');
    } catch (_) {}

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.alarm_on, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text("Time's Up!",
                  style: TextStyle(
                      color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "Great focus session! Stand up, stretch your hip flexors, roll your shoulders back, and take a sip of water.",
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("Got It", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _showFiveMinuteAlert() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            "5 minutes have passed. Check your posture, relax your shoulders, and stand or stretch briefly.",
          ),
          duration: Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _formatTime(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final percent = totalSeconds > 0
        ? (totalSeconds - remainingSeconds) / totalSeconds
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Posture & Focus Timer",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            tooltip: "Instant Posture Alert",
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active,
                  color: Color(0xFFE11D48), size: 18),
            ),
            onPressed: () async {
              try {
                await platform.invokeMethod('showPostureReminder');
              } catch (_) {}
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Preset selector chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: presets.map((p) {
                final isSelected = currentPreset == p['label'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: ChoiceChip(
                    label: Text(p['label'] as String),
                    selected: isSelected,
                    selectedColor: const Color(0xFF4F46E5),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFE2E8F0),
                    ),
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF64748B),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        _selectPreset(
                            p['label'] as String, p['seconds'] as int);
                      }
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: SwitchListTile.adaptive(
                value: fiveMinuteAlertsEnabled,
                onChanged: (enabled) =>
                    setState(() => fiveMinuteAlertsEnabled = enabled),
                activeThumbColor: const Color(0xFF4F46E5),
                title: const Text(
                  "5-minute posture alerts",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  fiveMinuteAlertsEnabled
                      ? "Remind me every 5 minutes while the timer runs"
                      : "Only alert me when the selected timer finishes",
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Circular Countdown Display in Light Card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircularPercentIndicator(
                radius: 125.0,
                lineWidth: 14.0,
                animation: false,
                percent: percent.clamp(0.0, 1.0),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: const Color(0xFF4F46E5),
                backgroundColor: const Color(0xFFEEF2FF),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(remainingSeconds),
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRunning ? "TRACKING SPINAL HEALTH" : "PAUSED",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isRunning
                            ? const Color(0xFF059669)
                            : const Color(0xFF94A3B8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset Button
                IconButton(
                  iconSize: 32,
                  tooltip: "Reset",
                  icon: const Icon(Icons.replay, color: Color(0xFF64748B)),
                  onPressed: _resetTimer,
                ),
                const SizedBox(width: 24),

                // Play / Pause Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(22),
                    backgroundColor: isRunning
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF4F46E5),
                    elevation: 4,
                  ),
                  onPressed: isRunning ? _pauseTimer : _startTimer,
                  child: Icon(
                    isRunning ? Icons.pause : Icons.play_arrow,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 24),

                // Manual Test Alert Button
                IconButton(
                  iconSize: 32,
                  tooltip: "Test Alert",
                  icon: const Icon(Icons.notification_add,
                      color: Color(0xFF059669)),
                  onPressed: () async {
                    try {
                      await platform.invokeMethod('showPostureReminder');
                    } catch (_) {}
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Live Posture Alignment Tip Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline,
                        color: Color(0xFF4F46E5), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ergonomic Posture Tip",
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          postureTips[currentTipIndex],
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
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
}
