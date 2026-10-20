import 'dart:math' as math;
import 'package:flutter/material.dart';

class ExerciseAnimationWidget extends StatefulWidget {
  final String exerciseId;
  final String title;
  final double height;
  final bool showControls;

  const ExerciseAnimationWidget({
    super.key,
    required this.exerciseId,
    required this.title,
    this.height = 200,
    this.showControls = true,
  });

  @override
  State<ExerciseAnimationWidget> createState() =>
      _ExerciseAnimationWidgetState();
}

class _ExerciseAnimationWidgetState extends State<ExerciseAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    // Each loop moves into the stretch, holds it, releases with control, then
    // pauses briefly before the next repetition.
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 36,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 14),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 36,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 14),
    ]).animate(_controller);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _controller.stop();
        _isPlaying = false;
      } else {
        _controller.repeat();
        _isPlaying = true;
      }
    });
  }

  String _getPhaseText(double cycle) {
    final normalizedId = widget.exerciseId.toLowerCase();
    late final List<String> cues;
    if (normalizedId.contains('ex-1') ||
        normalizedId.contains('hip') ||
        normalizedId.contains('lunge')) {
      cues = [
        "Ease hips forward & engage glute",
        "Hold stretch & breathe deeply",
        "Release the lunge slowly",
        "Reset for the next repetition"
      ];
    } else if (normalizedId.contains('ex-2') ||
        normalizedId.contains('bridge')) {
      cues = [
        "Press heels down & raise pelvis",
        "Squeeze glutes at the top",
        "Lower your hips with control",
        "Reset and keep knees aligned"
      ];
    } else if (normalizedId.contains('ex-3') ||
        normalizedId.contains('chin') ||
        normalizedId.contains('neck')) {
      cues = [
        "Draw chin straight backward",
        "Hold a long, neutral neck",
        "Release the tuck slowly",
        "Relax, then repeat gently"
      ];
    } else if (normalizedId.contains('ex-4') ||
        normalizedId.contains('pec') ||
        normalizedId.contains('door')) {
      cues = [
        "Step gently through the doorway",
        "Open chest & breathe into stretch",
        "Ease back with control",
        "Reset without shrugging shoulders"
      ];
    } else if (normalizedId.contains('ex-5') ||
        normalizedId.contains('cat') ||
        normalizedId.contains('cow')) {
      cues = [
        "Inhale: arch gently into Cow",
        "Pause and lengthen the spine",
        "Exhale: round into Cat",
        "Return to a neutral tabletop"
      ];
    } else {
      cues = [
        "Ease into the movement",
        "Hold steady & breathe slowly",
        "Release the stretch with control",
        "Reset for the next repetition"
      ];
    }
    if (cycle < 0.36) return cues[0];
    if (cycle < 0.50) return cues[1];
    if (cycle < 0.86) return cues[2];
    return cues[3];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF), Color(0xFFF0FDFA)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Ambient grid pattern backdrop
            Positioned.fill(
              child: CustomPaint(
                painter: _GridBackgroundPainter(),
              ),
            ),

            // Animated Figure
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ExerciseFigurePainter(
                    progress: _animation.value,
                    exerciseId: widget.exerciseId,
                  ),
                );
              },
            ),

            // Exercise Phase Label (Top Center)
            Positioned(
              top: 12,
              left: 16,
              right: widget.showControls ? 56 : 16,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isPlaying
                                ? const Color(0xFF059669)
                                : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: Text(
                              _getPhaseText(_controller.value),
                              key: ValueKey(_getPhaseText(_controller.value)),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Play / Pause Control
            if (widget.showControls)
              Positioned(
                top: 10,
                right: 12,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
                  elevation: 1,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _togglePlayPause,
                    child: Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 18,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom Alignment Badge
            Positioned(
              bottom: 10,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 12, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 4),
                    Text(
                      "Animated Biomechanical Guide",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.25)
      ..strokeWidth = 1;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ExerciseFigurePainter extends CustomPainter {
  final double progress;
  final String exerciseId;

  _ExerciseFigurePainter({
    required this.progress,
    required this.exerciseId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final bodyPaint = Paint()
      ..color = const Color(0xFF1E293B) // Slate 800
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = const Color(0xFF4F46E5) // Indigo 600
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = const Color(0xFF059669) // Emerald 600
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final pulsePaint = Paint()
      ..color =
          const Color(0xFF10B981).withValues(alpha: 0.25 + 0.35 * progress)
      ..style = PaintingStyle.fill;

    final floorPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.0;

    final normalizedId = exerciseId.toLowerCase();

    if (normalizedId.contains('ex-1') ||
        normalizedId.contains('hip') ||
        normalizedId.contains('lunge')) {
      _paintHipFlexorLunge(canvas, size, cx, cy, bodyPaint, jointPaint,
          highlightPaint, pulsePaint, floorPaint);
    } else if (normalizedId.contains('ex-2') ||
        normalizedId.contains('bridge')) {
      _paintGluteBridge(canvas, size, cx, cy, bodyPaint, jointPaint,
          highlightPaint, pulsePaint, floorPaint);
    } else if (normalizedId.contains('ex-3') ||
        normalizedId.contains('chin') ||
        normalizedId.contains('neck')) {
      _paintChinTuck(canvas, size, cx, cy, bodyPaint, jointPaint,
          highlightPaint, pulsePaint, floorPaint);
    } else if (normalizedId.contains('ex-4') ||
        normalizedId.contains('pec') ||
        normalizedId.contains('door')) {
      _paintDoorwayStretch(canvas, size, cx, cy, bodyPaint, jointPaint,
          highlightPaint, pulsePaint, floorPaint);
    } else if (normalizedId.contains('ex-5') ||
        normalizedId.contains('cat') ||
        normalizedId.contains('cow')) {
      _paintCatCow(canvas, size, cx, cy, bodyPaint, jointPaint, highlightPaint,
          pulsePaint, floorPaint);
    } else {
      _paintGenericStretch(canvas, size, cx, cy, bodyPaint, jointPaint,
          highlightPaint, pulsePaint, floorPaint);
    }
  }

  // 1. Hip Flexor Lunge Stretch
  void _paintHipFlexorLunge(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    Paint body,
    Paint joint,
    Paint highlight,
    Paint pulse,
    Paint floor,
  ) {
    final floorY = size.height * 0.82;
    canvas.drawLine(Offset(cx - 90, floorY), Offset(cx + 90, floorY), floor);

    final shift = progress * 24.0;
    final backKnee = Offset(cx - 50, floorY - 3);
    final backFoot = Offset(cx - 80, floorY - 3);
    final hip = Offset(cx - 20 + shift, floorY - 58);
    final frontKnee = Offset(cx + 35 + shift * 0.4, floorY - 38);
    final frontFoot = Offset(cx + 50, floorY - 3);
    final shoulder = Offset(cx - 15 + shift, floorY - 105);
    final head = Offset(cx - 12 + shift, floorY - 122);

    // Pulse on hip flexor
    canvas.drawCircle(hip, 14 + progress * 6, pulse);

    // Back leg & Foot
    canvas.drawLine(backFoot, backKnee, body);
    canvas.drawLine(backKnee, hip, body);

    // Front leg & Foot
    canvas.drawLine(hip, frontKnee, body);
    canvas.drawLine(frontKnee, frontFoot, body);

    // Torso
    canvas.drawLine(hip, shoulder, body);

    // Head
    canvas.drawCircle(head, 11, Paint()..color = const Color(0xFF1E293B));

    // Arms gently resting on front knee
    canvas.drawLine(shoulder, frontKnee + const Offset(-6, -10), body);

    // Highlight target hip flexor stretch arc
    canvas.drawArc(
      Rect.fromCircle(center: hip, radius: 18),
      math.pi / 2,
      math.pi / 2,
      false,
      highlight,
    );

    // Joints
    for (final p in [backKnee, hip, frontKnee, shoulder]) {
      canvas.drawCircle(p, 4.5, joint);
    }
  }

  // 2. Glute Bridges
  void _paintGluteBridge(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    Paint body,
    Paint joint,
    Paint highlight,
    Paint pulse,
    Paint floor,
  ) {
    final floorY = size.height * 0.78;
    canvas.drawLine(Offset(cx - 100, floorY), Offset(cx + 100, floorY), floor);

    final shoulder = Offset(cx - 65, floorY - 6);
    final head = Offset(cx - 85, floorY - 8);
    final feet = Offset(cx + 55, floorY - 3);

    // Hip lifts up from floor
    final hipY = (floorY - 6) - (progress * 42.0);
    final hip = Offset(cx - 12, hipY);

    // Knee height shifts slightly up
    final knee = Offset(cx + 42, floorY - 36 - progress * 14.0);

    // Glute pulse at peak
    if (progress > 0.4) {
      canvas.drawCircle(hip, 12 + progress * 8, pulse);
    }

    // Torso (Shoulder to Hip)
    canvas.drawLine(shoulder, hip, body);

    // Thigh (Hip to Knee)
    canvas.drawLine(hip, knee, body);

    // Shin (Knee to Foot)
    canvas.drawLine(knee, feet, body);

    // Arms flat on ground
    canvas.drawLine(shoulder, Offset(cx - 15, floorY - 3), body);

    // Head
    canvas.drawCircle(head, 10, Paint()..color = const Color(0xFF1E293B));

    // Target tension arc
    if (progress > 0.5) {
      canvas.drawArc(
        Rect.fromCircle(center: hip, radius: 16),
        -math.pi / 4,
        math.pi / 2,
        false,
        highlight,
      );
    }

    // Joints
    for (final p in [shoulder, hip, knee, feet]) {
      canvas.drawCircle(p, 4.5, joint);
    }
  }

  // 3. Chin Tucks & Neck Retraction
  void _paintChinTuck(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    Paint body,
    Paint joint,
    Paint highlight,
    Paint pulse,
    Paint floor,
  ) {
    final floorY = size.height * 0.82;
    final spineX = cx - 18;

    // Dotted neutral plumb line
    final plumbPaint = Paint()
      ..color = const Color(0xFF059669).withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    for (double y = floorY - 130; y < floorY - 30; y += 8) {
      canvas.drawLine(Offset(spineX, y), Offset(spineX, y + 4), plumbPaint);
    }

    final hip = Offset(spineX, floorY - 35);
    final shoulder = Offset(spineX, floorY - 85);

    // Head retracts backward as progress goes 0.0 -> 1.0
    final forwardOffset = (1.0 - progress) * 26.0;
    final neck = Offset(spineX + forwardOffset * 0.5, floorY - 95);
    final head = Offset(spineX + forwardOffset, floorY - 114);

    // Pulse around cervical spine
    canvas.drawCircle(neck, 12 + progress * 6, pulse);

    // Torso / Spine
    canvas.drawLine(hip, shoulder, body);

    // Neck
    canvas.drawLine(shoulder, neck, highlight);

    // Head
    canvas.drawCircle(head, 13, Paint()..color = const Color(0xFF1E293B));

    // Chin indicator point
    final chin = head + const Offset(12, 8);
    canvas.drawCircle(chin, 3, Paint()..color = const Color(0xFFE11D48));

    // Alignment arrow showing backward motion
    final arrowStart = Offset(spineX + 32, floorY - 114);
    final arrowEnd = Offset(spineX + 16, floorY - 114);
    canvas.drawLine(arrowStart, arrowEnd, highlight);

    // Joints
    for (final p in [hip, shoulder, neck]) {
      canvas.drawCircle(p, 4.5, joint);
    }
  }

  // 4. Doorway Pec Stretch
  void _paintDoorwayStretch(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    Paint body,
    Paint joint,
    Paint highlight,
    Paint pulse,
    Paint floor,
  ) {
    final floorY = size.height * 0.82;
    canvas.drawLine(Offset(cx - 90, floorY), Offset(cx + 90, floorY), floor);

    // Doorframe post
    final doorX = cx - 45;
    canvas.drawLine(
      Offset(doorX, floorY - 135),
      Offset(doorX, floorY),
      Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.square,
    );

    final shift = progress * 26.0;
    final backFoot = Offset(cx - 30, floorY - 3);
    final frontFoot = Offset(cx + 35 + shift * 0.5, floorY - 3);
    final hip = Offset(cx - 5 + shift, floorY - 55);
    final shoulder = Offset(cx + shift, floorY - 98);
    final head = Offset(cx + 6 + shift, floorY - 116);

    // Arm anchored on door frame at 90 degrees
    final elbow = Offset(doorX + 3, floorY - 95);
    final hand = Offset(doorX + 3, floorY - 125);

    // Chest expansion pulse
    canvas.drawCircle(
        shoulder + const Offset(12, 10), 14 + progress * 8, pulse);

    // Doorway arm
    canvas.drawLine(shoulder, elbow, highlight);
    canvas.drawLine(elbow, hand, highlight);

    // Legs
    canvas.drawLine(hip, backFoot, body);
    canvas.drawLine(hip, frontFoot, body);

    // Torso
    canvas.drawLine(hip, shoulder, body);

    // Free arm
    canvas.drawLine(shoulder, Offset(shoulder.dx + 18, shoulder.dy + 35), body);

    // Head
    canvas.drawCircle(head, 11, Paint()..color = const Color(0xFF1E293B));

    // Chest stretch arc
    canvas.drawArc(
      Rect.fromCircle(center: shoulder, radius: 18),
      -math.pi / 3,
      math.pi / 2,
      false,
      highlight,
    );

    for (final p in [hip, shoulder, elbow, hand]) {
      canvas.drawCircle(p, 4.5, joint);
    }
  }

  // 5. Cat-Cow Spinal Mobilization
  void _paintCatCow(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    Paint body,
    Paint joint,
    Paint highlight,
    Paint pulse,
    Paint floor,
  ) {
    final floorY = size.height * 0.80;
    canvas.drawLine(Offset(cx - 95, floorY), Offset(cx + 95, floorY), floor);

    final hands = Offset(cx + 45, floorY - 3);
    final knees = Offset(cx - 45, floorY - 3);
    final feet = Offset(cx - 75, floorY - 3);

    final shoulders = Offset(cx + 45, floorY - 45);
    final hips = Offset(cx - 45, floorY - 48);

    // Spine curve animation:
    // progress = 0.0 (Cow - dipped/concave), progress = 1.0 (Cat - arched/convex)
    final midSpineY = (floorY - 36) - progress * 32.0;
    final midSpine = Offset(cx, midSpineY);

    // Head moves opposite to spine
    final headY = (floorY - 60) + progress * 24.0;
    final head = Offset(cx + 62, headY);

    // Spine curve path
    final spinePath = Path();
    spinePath.moveTo(hips.dx, hips.dy);
    spinePath.quadraticBezierTo(
        midSpine.dx, midSpine.dy, shoulders.dx, shoulders.dy);

    // Pulse along mid spine
    canvas.drawCircle(midSpine, 12 + progress * 6, pulse);

    // Arms & Thighs
    canvas.drawLine(hands, shoulders, body);
    canvas.drawLine(knees, hips, body);
    canvas.drawLine(knees, feet, body);

    // Curved spine
    canvas.drawPath(spinePath, highlight);

    // Neck & Head
    canvas.drawLine(shoulders, head, body);
    canvas.drawCircle(head, 10, Paint()..color = const Color(0xFF1E293B));

    for (final p in [hands, knees, hips, shoulders, midSpine]) {
      canvas.drawCircle(p, 4.5, joint);
    }
  }

  // Fallback: Generic Posture Realignment
  void _paintGenericStretch(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    Paint body,
    Paint joint,
    Paint highlight,
    Paint pulse,
    Paint floor,
  ) {
    final floorY = size.height * 0.82;
    canvas.drawLine(Offset(cx - 60, floorY), Offset(cx + 60, floorY), floor);

    final shift = progress * 15.0;
    final hips = Offset(cx, floorY - 48);
    final shoulders = Offset(cx, floorY - 95);
    final head = Offset(cx, floorY - 114);

    canvas.drawCircle(shoulders, 14 + progress * 6, pulse);

    canvas.drawLine(hips, Offset(cx - 18, floorY - 3), body);
    canvas.drawLine(hips, Offset(cx + 18, floorY - 3), body);
    canvas.drawLine(hips, shoulders, body);

    // Arms raising up
    canvas.drawLine(
        shoulders, Offset(cx - 24 - shift, floorY - 120 - shift), highlight);
    canvas.drawLine(
        shoulders, Offset(cx + 24 + shift, floorY - 120 - shift), highlight);

    canvas.drawCircle(head, 11, Paint()..color = const Color(0xFF1E293B));

    for (final p in [hips, shoulders]) {
      canvas.drawCircle(p, 4.5, joint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExerciseFigurePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.exerciseId != exerciseId;
  }
}
