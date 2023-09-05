import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/drawing_mode.dart';

class Sketch {
  const Sketch({
    required this.points,
    this.color = Colors.black,
    this.type = SketchType.scribble,
    this.filled = true,
    this.sides = 3,
    required this.size,
  });

  factory Sketch.fromDrawingMode(
    Sketch sketch,
    DrawingMode drawingMode,
    bool filled,
  ) {
    return Sketch(
      points: sketch.points,
      color: sketch.color,
      size: sketch.size,
      filled: filled &&
          drawingMode != DrawingMode.line &&
          drawingMode != DrawingMode.pencil &&
          drawingMode != DrawingMode.eraser,
      sides: sketch.sides,
      type: () {
        switch (drawingMode) {
          case DrawingMode.eraser:
            return SketchType.eraser;
          case DrawingMode.pencil:
            return SketchType.scribble;
          case DrawingMode.line:
            return SketchType.line;
          case DrawingMode.square:
            return SketchType.square;
          case DrawingMode.circle:
            return SketchType.circle;
          case DrawingMode.polygon:
            return SketchType.polygon;
          // ignore: no_default_cases
          default:
            return SketchType.scribble;
        }
      }(),
    );
  }

  factory Sketch.fromJson(Map<String, dynamic> json) {
    final points = (json['points'] as List<Map<String, dynamic>>)
        .map(_offsetFromJson)
        .toList();

    return Sketch(
      points: points,
      color: (json['color'] as String).toColor(),
      size: json['size'] as double,
      filled: json['filled'] as bool,
      type: (json['type'] as String).toSketchTypeEnum(),
      sides: json['sides'] as int,
    );
  }

  final List<Offset> points;
  final Color color;
  final double size;
  final SketchType type;
  final bool filled;
  final int sides;

  Map<String, dynamic> toJson() {
    final pointsMap = points.map(_offsetToJson).toList();

    return {
      'points': pointsMap,
      'color': color.toHex(),
      'size': size,
      'filled': filled,
      'type': type.toRegularString(),
      'sides': sides,
    };
  }

  static Offset _offsetFromJson(Map<String, dynamic> json) {
    final dx = (json['dx'] as num).toDouble();
    final dy = (json['dy'] as num).toDouble();

    return Offset(dx, dy);
  }

  static Map<String, dynamic> _offsetToJson(Offset offset) {
    return {'dx': offset.dx, 'dy': offset.dy};
  }
}

enum SketchType { scribble, eraser, line, square, circle, polygon }

extension SketchTypeX on SketchType {
  String toRegularString() => toString().split('.')[1];
}

extension SketchTypeExtension on String {
  SketchType toSketchTypeEnum() =>
      SketchType.values.firstWhere((e) => e.toString() == 'SketchType.$this');
}

extension ColorExtension on String {
  Color toColor() {
    var hexColor = replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }

    return hexColor.length == 8
        ? Color(int.parse('0x$hexColor'))
        : Colors.black;
  }
}

extension ColorExtensionX on Color {
  String toHex() => '#${value.toRadixString(16).substring(2, 8)}';
}
