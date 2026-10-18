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
  String currentPreset = "25m Focus";

  final List<Map<String, dynamic>> presets = [
    {"label": "25m Focus", "seconds": 25 * 60, "desc": "Posture Pomodoro"},
    {"label": "45m Stand", "seconds": 45 * 60, "desc": "Sitting Limit"},
    {"label": "5m Reset", "seconds": 5 * 60, "desc": "Spinal Stretch"},
  ];

  final List<String> postureTips = [
    "Keep monitor at eye level to prevent forward head tilt.",
    "Elbows at 90° angle, resting lightly on armrests.",
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
          backgroundColor: const Color(0xFF1A1F2B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.alarm_on, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text("Time's Up!", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "Great focus session! Stand up, stretch your hip flexors, roll your shoulders back, and take a sip of water.",
            style: TextStyle(color: Color(0xFFA1A1AA)),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Got It", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
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
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        elevation: 0,
        title: const Text(
          "Posture & Focus Timer",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: "Instant Posture Alert",
            icon: const Icon(Icons.notifications_active, color: Color(0xFFFF6B88)),
            onPressed: () async {
              try {
                await platform.invokeMethod('showPostureReminder');
              } catch (_) {}
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Preset selector chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: presets.map((p) {
                final isSelected = currentPreset == p['label'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(p['label'] as String),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6366F1),
                    backgroundColor: const Color(0xFF1A1F2B),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        _selectPreset(p['label'] as String, p['seconds'] as int);
                      }
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 35),

            // Circular Countdown Display
            CircularPercentIndicator(
              radius: 125.0,
              lineWidth: 14.0,
              animation: false,
              percent: percent.clamp(0.0, 1.0),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: const Color(0xFF6366F1),
              backgroundColor: const Color(0xFF1A1F2B),
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(remainingSeconds),
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRunning ? "TRACKING SPINAL HEALTH" : "PAUSED",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isRunning ? const Color(0xFF10B981) : const Color(0xFFA1A1AA),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset Button
                IconButton(
                  iconSize: 34,
                  tooltip: "Reset",
                  icon: const Icon(Icons.replay, color: Color(0xFFA1A1AA)),
                  onPressed: _resetTimer,
                ),
                const SizedBox(width: 24),

                // Play / Pause Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(22),
                    backgroundColor: isRunning ? const Color(0xFFFF6B88) : const Color(0xFF6366F1),
                    elevation: 6,
                  ),
                  onPressed: isRunning ? _pauseTimer : _startTimer,
                  child: Icon(
                    isRunning ? Icons.pause : Icons.play_arrow,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 24),

                // Skip / Alert Button
                IconButton(
                  iconSize: 34,
                  tooltip: "Test Alert",
                  icon: const Icon(Icons.notification_add, color: Color(0xFF10B981)),
                  onPressed: () async {
                    try {
                      await platform.invokeMethod('showPostureReminder');
                    } catch (_) {}
                  },
                ),
              ],
            ),

            const SizedBox(height: 35),

            // Live Posture Alignment Tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline, color: Color(0xFF6366F1), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ergonomic Posture Tip",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          postureTips[currentTipIndex],
                          style: const TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 12,
                            height: 1.3,
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
