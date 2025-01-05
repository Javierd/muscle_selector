import 'package:flutter/material.dart';
import 'package:muscle_selector/muscle_selector.dart';
import 'package:muscle_selector/src/size_controller.dart';

class MusclePainter extends CustomPainter {
  final Muscle muscle;
  final bool selected;
  final Color? strokeColor;
  final Color? selectedColor;
  final Color? dotColor;

  final sizeController = SizeController.instance;

  double _scale = 1.0;

  MusclePainter({
    required this.muscle,
    required this.selected,
    this.selectedColor,
    this.strokeColor,
    this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = strokeColor ?? Colors.white60
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final selectedPen = Paint()
      ..color = selectedColor ?? Colors.blue
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    _scale = sizeController.calculateScale(size);
    canvas.scale(_scale);

    if (selected) {
      canvas.drawPath(muscle.path, selectedPen);
    }

    canvas.drawPath(muscle.path, pen);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  bool hitTest(Offset position) {
    double inverseScale = sizeController.inverseOfScale(_scale);
    return muscle.path.contains(position.scale(inverseScale, inverseScale));
  }
}
