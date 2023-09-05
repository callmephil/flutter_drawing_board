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
    if (currentSketch.value == null) return;

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
      drawBackgroundImage(canvas, size, backgroundImage!);
    }
    for (final sketch in sketches) {
      final points = sketch.points;
      if (points.isEmpty) return;

      final path = createPath(points);
      final paint = createPaint(sketch);

      // define first and last points for convenience
      final firstPoint = sketch.points.first;
      final lastPoint = sketch.points.last;

      // create rect to use rectangle and circle
      final rect = Rect.fromPoints(firstPoint, lastPoint);

      // Calculate center point from the first and last points
      final centerPoint = (firstPoint / 2) + (lastPoint / 2);

      // Calculate path's radius from the first and last points
      final radius = (firstPoint - lastPoint).distance / 2;

      drawSketch(canvas, sketch, path, paint, rect, centerPoint, radius);
    }
  }

  static void drawBackgroundImage(Canvas canvas, Size size, Image image) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );
  }

  Path createPath(List<Offset> points) {
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

    return path;
  }

  Paint createPaint(Sketch sketch) {
    final paint = Paint()
      ..color = sketch.color
      ..strokeCap = StrokeCap.round;

    if (!sketch.filled) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = sketch.size;
    }

    return paint;
  }

  // ignore: long-parameter-list
  static void drawSketch(
    Canvas canvas,
    Sketch sketch,
    Path path,
    Paint paint,
    Rect rect,
    Offset centerPoint,
    double radius,
  ) {
    switch (sketch.type) {
      case SketchType.eraser:
        drawEraser(canvas, path, paint);
      case SketchType.scribble:
        drawScribble(canvas, path, paint);
      case SketchType.square:
        drawSquare(canvas, rect, paint);
      case SketchType.line:
        drawLine(canvas, sketch, paint);
      case SketchType.circle:
        drawCircle(canvas, rect, paint);
      case SketchType.polygon:
        drawPolygon(canvas, sketch, paint, centerPoint, radius);
    }
  }

  static void drawEraser(Canvas canvas, Path path, Paint paint) {
    paint
      ..blendMode = BlendMode.clear
      ..color = Colors.white;
    canvas.drawPath(path, paint);
  }

  static void drawScribble(Canvas canvas, Path path, Paint paint) {
    canvas.drawPath(path, paint);
  }

  static void drawSquare(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      paint,
    );
  }

  static void drawLine(Canvas canvas, Sketch sketch, Paint paint) {
    canvas.drawLine(sketch.points.first, sketch.points.last, paint);
  }

  static void drawCircle(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawOval(rect, paint);
  }

  // ignore: long-parameter-list
  static void drawPolygon(
    Canvas canvas,
    Sketch sketch,
    Paint paint,
    Offset centerPoint,
    double radius,
  ) {
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
      child: RepaintBoundary(
        child: SizedBox(
          height: height,
          width: width,
          child: ValueListenableBuilder(
            valueListenable: currentSketch,
            builder: (context, sketch, child) {
              return CustomPaint(
                painter: SketchPainter(
                  sketches: sketch == null ? [] : [sketch],
                ),
              );
            },
          ),
        ),
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
      child: RepaintBoundary(
        key: canvasGlobalKey,
        child: SizedBox(
          height: height,
          width: width,
          child: ColoredBox(
            color: kCanvasColor,
            child: ValueListenableBuilder<List<Sketch>>(
              valueListenable: allSketches,
              builder: (_, sketches, __) {
                return CustomPaint(
                  painter: SketchPainter(
                    sketches: sketches,
                    backgroundImage: backgroundImage.value,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
