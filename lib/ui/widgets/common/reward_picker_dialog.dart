import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_theme.dart';

class RewardPickerDialog extends StatefulWidget {
  final int initialValue;

  const RewardPickerDialog({
    super.key,
    this.initialValue = 10,
  });

  @override
  State<RewardPickerDialog> createState() => _RewardPickerDialogState();
}

class _RewardPickerDialogState extends State<RewardPickerDialog> {
  late int _currentValue;
  static const int _minValue = 0;
  static const int _maxValue = 200;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(_minValue, _maxValue);
  }

  void _increment() {
    setState(() {
      if (_currentValue < _maxValue) {
        _currentValue++;
      }
    });
  }

  void _decrement() {
    setState(() {
      if (_currentValue > _minValue) {
        _currentValue--;
      }
    });
  }

  void _onKnobChanged(double angle) {
    final normalizedAngle = (angle % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    final progress = normalizedAngle / (2 * math.pi);
    final newValue = (_minValue + progress * (_maxValue - _minValue)).round();
    
    setState(() {
      _currentValue = newValue.clamp(_minValue, _maxValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set Reward Points',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _CircularKnob(
                    value: _currentValue,
                    minValue: _minValue,
                    maxValue: _maxValue,
                    onChanged: _onKnobChanged,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.expand_less, size: 32),
                        color: AppTheme.textSecondary,
                        onPressed: _increment,
                      ),
                      const SizedBox(height: 8),
                      _ValueDisplay(value: _currentValue),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.expand_more, size: 32),
                        color: AppTheme.textSecondary,
                        onPressed: _decrement,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context, _currentValue),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularKnob extends StatefulWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<double> onChanged;

  const _CircularKnob({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  State<_CircularKnob> createState() => _CircularKnobState();
}

class _CircularKnobState extends State<_CircularKnob> {
  void _updateAngle(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = math.atan2(
      localPosition.dy - center.dy,
      localPosition.dx - center.dx,
    );
    widget.onChanged(angle + math.pi / 2);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        _updateAngle(localPosition, box.size);
      },
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.localPosition);
        _updateAngle(localPosition, box.size);
      },
      child: CustomPaint(
        size: const Size(280, 280),
        painter: _KnobPainter(
          value: widget.value,
          minValue: widget.minValue,
          maxValue: widget.maxValue,
        ),
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  final int value;
  final int minValue;
  final int maxValue;

  _KnobPainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    final trackPaint = Paint()
      ..color = AppTheme.border
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final progress = (value - minValue) / (maxValue - minValue);
    final sweepAngle = 2 * math.pi * progress;

    final progressPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    final indicatorAngle = -math.pi / 2 + sweepAngle;
    final indicatorX = center.dx + radius * math.cos(indicatorAngle);
    final indicatorY = center.dy + radius * math.sin(indicatorAngle);

    final indicatorPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(indicatorX, indicatorY), 8, indicatorPaint);

    final indicatorBorderPaint = Paint()
      ..color = AppTheme.background
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(indicatorX, indicatorY), 8, indicatorBorderPaint);
  }

  @override
  bool shouldRepaint(_KnobPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _ValueDisplay extends StatelessWidget {
  final int value;

  const _ValueDisplay({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const FaIcon(
                FontAwesomeIcons.gem,
                size: 24,
                color: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 100,
            color: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
