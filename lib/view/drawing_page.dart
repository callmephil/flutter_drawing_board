import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_drawing_board/main.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/drawing_canvas.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/drawing_mode.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/sketch.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/widgets/canvas_side_bar.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  @override
  Widget build(BuildContext context) {
    final selectedColor = ValueNotifier(Colors.black);
    final strokeSize = ValueNotifier<double>(10);
    final eraserSize = ValueNotifier<double>(30);
    final drawingMode = ValueNotifier(DrawingMode.pencil);
    final filled = ValueNotifier<bool>(false);
    final polygonSides = ValueNotifier<int>(3);
    final backgroundImage = ValueNotifier<Image?>(null);

    final canvasGlobalKey = GlobalKey();

    final currentSketch = ValueNotifier<Sketch?>(null);
    final allSketches = ValueNotifier<List<Sketch>>([]);

    return Scaffold(
      drawer: Drawer(
        child: CanvasSideBar(
          drawingMode: drawingMode,
          selectedColor: selectedColor,
          strokeSize: strokeSize,
          eraserSize: eraserSize,
          currentSketch: currentSketch,
          allSketches: allSketches,
          canvasGlobalKey: canvasGlobalKey,
          filled: filled,
          polygonSides: polygonSides,
          backgroundImage: backgroundImage,
        ),
      ),
      appBar: AppBar(
        title: const Text(
          "Let's Draw",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: ColoredBox(
          color: kCanvasColor,
          child: DrawingCanvas(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            drawingMode: drawingMode,
            selectedColor: selectedColor,
            strokeSize: strokeSize,
            eraserSize: eraserSize,
            currentSketch: currentSketch,
            allSketches: allSketches,
            canvasGlobalKey: canvasGlobalKey,
            filled: filled,
            polygonSides: polygonSides,
            backgroundImage: backgroundImage,
          ),
        ),
      ),
    );
  }
}
