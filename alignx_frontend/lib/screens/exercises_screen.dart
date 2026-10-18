import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../services/api_service.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<Exercise> exercises = [];
  bool isLoading = true;
  String selectedFilter = 'All';

  final List<String> filters = ['All', 'APT', 'Spine', 'Neck & Chest'];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => isLoading = true);
    final data = await ApiService.fetchPostureExercises();
    if (mounted) {
      setState(() {
        exercises = data;
        isLoading = false;
      });
    }
  }

  List<Exercise> get filteredExercises {
    if (selectedFilter == 'All') return exercises;
    if (selectedFilter == 'APT') {
      return exercises
          .where((e) =>
              e.targetArea.contains('APT') ||
              e.targetArea.contains('Pelvic') ||
              e.targetArea.contains('Hip') ||
              e.targetArea.contains('Glute'))
          .toList();
    }
    if (selectedFilter == 'Spine') {
      return exercises
          .where((e) =>
              e.targetArea.contains('Spine') || e.targetArea.contains('Lumbar'))
          .toList();
    }
    if (selectedFilter == 'Neck & Chest') {
      return exercises
          .where((e) =>
              e.targetArea.contains('Neck') ||
              e.targetArea.contains('Chest') ||
              e.targetArea.contains('Pec') ||
              e.targetArea.contains('Head'))
          .toList();
    }
    return exercises;
  }

  void _showExerciseDetailModal(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1F2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exercise.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    exercise.difficulty,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Text(
                  exercise.duration,
                  style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.track_changes, size: 16, color: Color(0xFFFF6B88)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    exercise.targetArea,
                    style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 28),
            const Text(
              "How to Perform",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.instructions,
              style: const TextStyle(
                color: Color(0xFFA1A1AA),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Alignment Benefits",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.benefits,
              style: const TextStyle(
                color: Color(0xFFA1A1AA),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_circle_outline, color: Colors.white),
              label: const Text(
                "Start Guided Stretch (30s)",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _startQuickGuidedStretch(exercise);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startQuickGuidedStretch(Exercise exercise) {
    int seconds = 30;
    Timer? stretchTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          stretchTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (seconds > 1) {
              setDialogState(() => seconds--);
            } else {
              t.cancel();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF10B981),
                  content: Text("Finished: ${exercise.title}! Great posture check!"),
                ),
              );
            }
          });

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1F2B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              exercise.title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$seconds",
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Hold stretch with steady breathing...",
                  style: TextStyle(color: Color(0xFFA1A1AA)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  stretchTimer?.cancel();
                  Navigator.pop(ctx);
                },
                child: const Text("Stop", style: TextStyle(color: Color(0xFFFF6B88))),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        elevation: 0,
        title: const Text(
          "Posture & Pelvic Tilt Exercises",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Exercises',
            icon: const Icon(Icons.refresh, color: Color(0xFFA1A1AA)),
            onPressed: _loadExercises,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
          : Column(
              children: [
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: filters.map((f) {
                      final isSelected = selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: isSelected,
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: const Color(0xFF1A1F2B),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedFilter = f);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // Exercise List
                Expanded(
                  child: filteredExercises.isEmpty
                      ? const Center(
                          child: Text(
                            "No exercises match this filter.",
                            style: TextStyle(color: Color(0xFFA1A1AA)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredExercises.length,
                          itemBuilder: (context, index) {
                            final exercise = filteredExercises[index];
                            return _buildExerciseCard(exercise);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.self_improvement, color: Color(0xFF6366F1), size: 26),
        ),
        title: Text(
          exercise.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                exercise.duration,
                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.targetArea,
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFA1A1AA)),
        onTap: () => _showExerciseDetailModal(exercise),
      ),
    );
  }
}
