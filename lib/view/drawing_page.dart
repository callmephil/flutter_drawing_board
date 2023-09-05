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
      backgroundColor: kCanvasColor,
      key: const ValueKey('drawing_scaffold'),
      endDrawer: Drawer(
        key: const ValueKey('drawing_drawer'),
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
      body: Stack(
        key: const ValueKey('drawing_stack'),
        children: [
          DrawingCanvas(
            key: const ValueKey('drawing_canvas'),
            width: double.infinity,
            height: double.infinity,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            key: const ValueKey('drawing_drawer_button_row'),
            children: [
              if (Navigator.of(context).canPop())
                ColoredBox(
                  key: const ValueKey('drawing_back_button'),
                  color: kCanvasColor,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              const Spacer(),
              const ColoredBox(
                key: ValueKey('drawing_drawer_button'),
                color: kCanvasColor,
                child: EndDrawerButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
