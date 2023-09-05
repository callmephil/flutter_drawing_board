import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_drawing_board/main.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/drawing_mode.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/sketch.dart';

class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({
    super.key,
    required this.height,
    required this.width,
    required this.selectedColor,
    required this.strokeSize,
    required this.eraserSize,
    required this.drawingMode,
    required this.currentSketch,
    required this.allSketches,
    required this.canvasGlobalKey,
    required this.filled,
    required this.polygonSides,
    required this.backgroundImage,
  });
  final double height;
  final double width;
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<Image?> backgroundImage;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<int> polygonSides;
  final ValueNotifier<bool> filled;

  bool get _isErasing => drawingMode.value == DrawingMode.eraser;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: Stack(
        children: [
          BuildAllSketches(
            height: height,
            width: width,
            allSketches: allSketches,
            canvasGlobalKey: canvasGlobalKey,
            backgroundImage: backgroundImage,
          ),
          BuildCurrentPath(
            onPointerDown: (details) => onPointerDown(details, context),
            onPointerMove: (details) => onPointerMove(details, context),
            onPointerUp: onPointerUp,
            currentSketch: currentSketch,
            height: height,
            width: width,
          ),
        ],
      ),
    );
  }

  void onPointerDown(PointerDownEvent details, BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox) {
      debugPrint('Box is not a RenderBox');

      return;
    }
    final offset = box.globalToLocal(details.position);
    currentSketch.value = _fromDrawingMode([offset]);
  }

  void onPointerMove(PointerMoveEvent details, BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox) {
      debugPrint('Box is not a RenderBox');

      return;
    }

    final offset = box.globalToLocal(details.position);
    final points = List<Offset>.from(currentSketch.value?.points ?? [])
      ..add(offset);
    currentSketch.value = _fromDrawingMode(points);
  }

  Sketch _fromDrawingMode(List<Offset> offsets) {
    return Sketch.fromDrawingMode(
      Sketch(
        points: offsets,
        size: _isErasing ? eraserSize.value : strokeSize.value,
        color: _isErasing ? kCanvasColor : selectedColor.value,
        sides: polygonSides.value,
      ),
      drawingMode.value,
      filled.value,
    );
  }

  void onPointerUp(PointerUpEvent _) {
    allSketches.value = List<Sketch>.from(allSketches.value)
      ..add(currentSketch.value!);
  }
}

class SketchPainter extends CustomPainter {
  const SketchPainter({
    this.backgroundImage,
    required this.sketches,
  });
  final List<Sketch> sketches;
  final Image? backgroundImage;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(
          0,
          0,
          backgroundImage!.width.toDouble(),
          backgroundImage!.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    }
    for (final sketch in sketches) {
      final points = sketch.points;
      if (points.isEmpty) return;

      final path = Path()..moveTo(points[0].dx, points[0].dy);
      if (points.length < 2) {
        // If the path only has one line, draw a dot.
        path.addOval(
          Rect.fromCircle(
            center: Offset(points[0].dx, points[0].dy),
            radius: 1,
          ),
        );
      }

      for (var i = 1; i < points.length - 1; ++i) {
        final p0 = points[i];
        final p1 = points[i + 1];
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }

      final paint = Paint()
        ..color = sketch.color
        ..strokeCap = StrokeCap.round;

      if (!sketch.filled) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = sketch.size;
      }

      // define first and last points for convenience
      final firstPoint = sketch.points.first;
      final lastPoint = sketch.points.last;

      // create rect to use rectangle and circle
      final rect = Rect.fromPoints(firstPoint, lastPoint);

      // Calculate center point from the first and last points
      final centerPoint = (firstPoint / 2) + (lastPoint / 2);

      // Calculate path's radius from the first and last points
      final radius = (firstPoint - lastPoint).distance / 2;

      if (sketch.type == SketchType.eraser) {
        paint
          ..blendMode = BlendMode.clear
          ..color = Colors.white;
        canvas.drawPath(path, paint);
      } else if (sketch.type == SketchType.scribble) {
        canvas.drawPath(path, paint);
      } else if (sketch.type == SketchType.square) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          paint,
        );
      } else if (sketch.type == SketchType.line) {
        canvas.drawLine(firstPoint, lastPoint, paint);
      } else if (sketch.type == SketchType.circle) {
        canvas.drawOval(rect, paint);
        // Uncomment this line if you need a PERFECT CIRCLE
        // canvas.drawCircle(centerPoint, radius , paint);
      } else if (sketch.type == SketchType.polygon) {
        final polygonPath = Path();
        final sides = sketch.sides;
        final angle = (math.pi * 2) / sides;

        const radian = 0;

        final startPoint =
            Offset(radius * math.cos(radian), radius * math.sin(radian));

        polygonPath.moveTo(
          startPoint.dx + centerPoint.dx,
          startPoint.dy + centerPoint.dy,
        );
        for (var i = 1; i <= sides; i++) {
          final x = radius * math.cos(radian + angle * i) + centerPoint.dx;
          final y = radius * math.sin(radian + angle * i) + centerPoint.dy;
          polygonPath.lineTo(x, y);
        }
        polygonPath.close();
        canvas.drawPath(polygonPath, paint);
      }
    }

    canvas
      ..saveLayer(Rect.largest, Paint())
      ..restore();
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) {
    return oldDelegate.sketches != sketches;
  }
}

class BuildCurrentPath extends StatelessWidget {
  const BuildCurrentPath({
    super.key,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.currentSketch,
    required this.height,
    required this.width,
  });

  final void Function(PointerDownEvent)? onPointerDown;
  final void Function(PointerMoveEvent)? onPointerMove;
  final void Function(PointerUpEvent)? onPointerUp;
  final ValueNotifier<Sketch?> currentSketch;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      child: ValueListenableBuilder(
        valueListenable: currentSketch,
        builder: (context, sketch, child) {
          return RepaintBoundary(
            child: SizedBox(
              height: height,
              width: width,
              child: CustomPaint(
                painter: SketchPainter(
                  sketches: sketch == null ? [] : [sketch],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BuildAllSketches extends StatelessWidget {
  const BuildAllSketches({
    super.key,
    required this.height,
    required this.width,
    required this.allSketches,
    required this.canvasGlobalKey,
    required this.backgroundImage,
  });

  final double height;
  final double width;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey<State<StatefulWidget>> canvasGlobalKey;
  final ValueNotifier<Image?> backgroundImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ValueListenableBuilder<List<Sketch>>(
        valueListenable: allSketches,
        builder: (context, sketches, __) {
          return RepaintBoundary(
            key: canvasGlobalKey,
            child: SizedBox(
              height: height,
              width: width,
              child: ColoredBox(
                color: kCanvasColor,
                child: CustomPaint(
                  painter: SketchPainter(
                    sketches: sketches,
                    backgroundImage: backgroundImage.value,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
