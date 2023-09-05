import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/main.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/drawing_mode.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/sketch.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/widgets/color_palette.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

class CanvasSideBar extends HookWidget {
  const CanvasSideBar({
    super.key,
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
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<bool> filled;
  final ValueNotifier<int> polygonSides;
  final ValueNotifier<ui.Image?> backgroundImage;

  @override
  Widget build(BuildContext context) {
    final undoRedoStack = useState(
      _UndoRedoStack(
        sketchesNotifier: allSketches,
        currentSketchNotifier: currentSketch,
      ),
    );
    final scrollController = useScrollController();

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: ListView(
        padding: const EdgeInsets.all(10),
        controller: scrollController,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Shapes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _IconBox(
                iconData: FontAwesomeIcons.pencil,
                selected: drawingMode.value == DrawingMode.pencil,
                onTap: () => drawingMode.value = DrawingMode.pencil,
                tooltip: 'Pencil',
              ),
              _IconBox(
                selected: drawingMode.value == DrawingMode.line,
                onTap: () => drawingMode.value = DrawingMode.line,
                tooltip: 'Line',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 2,
                      child: ColoredBox(
                        color: drawingMode.value == DrawingMode.line
                            ? Colors.grey.shade900
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              _IconBox(
                iconData: Icons.hexagon_outlined,
                selected: drawingMode.value == DrawingMode.polygon,
                onTap: () => drawingMode.value = DrawingMode.polygon,
                tooltip: 'Polygon',
              ),
              _IconBox(
                iconData: FontAwesomeIcons.eraser,
                selected: drawingMode.value == DrawingMode.eraser,
                onTap: () => drawingMode.value = DrawingMode.eraser,
                tooltip: 'Eraser',
              ),
              _IconBox(
                iconData: FontAwesomeIcons.square,
                selected: drawingMode.value == DrawingMode.square,
                onTap: () => drawingMode.value = DrawingMode.square,
                tooltip: 'Square',
              ),
              _IconBox(
                iconData: FontAwesomeIcons.circle,
                selected: drawingMode.value == DrawingMode.circle,
                onTap: () => drawingMode.value = DrawingMode.circle,
                tooltip: 'Circle',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Fill Shape: ',
                style: TextStyle(fontSize: 12),
              ),
              Checkbox(
                value: filled.value,
                onChanged: (val) {
                  filled.value = val ?? false;
                },
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: drawingMode.value == DrawingMode.polygon
                ? Row(
                    children: [
                      const Text(
                        'Polygon Sides: ',
                        style: TextStyle(fontSize: 12),
                      ),
                      Slider(
                        value: polygonSides.value.toDouble(),
                        min: 3,
                        max: 8,
                        onChanged: (val) {
                          polygonSides.value = val.toInt();
                        },
                        label: '${polygonSides.value}',
                        divisions: 5,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
          const Text(
            'Colors',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ColorPalette(
            selectedColor: selectedColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'Size',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Row(
            children: [
              const Text(
                'Stroke Size: ',
                style: TextStyle(fontSize: 12),
              ),
              Slider(
                value: strokeSize.value,
                min: 1,
                max: 50,
                divisions: 50,
                label: strokeSize.value.toStringAsFixed(0),
                onChanged: (val) {
                  strokeSize.value = val;
                },
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Eraser Size: ',
                style: TextStyle(fontSize: 12),
              ),
              Slider(
                value: eraserSize.value,
                min: 1,
                max: 80,
                divisions: 80,
                label: eraserSize.value.toStringAsFixed(0),
                onChanged: (val) {
                  eraserSize.value = val;
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Actions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Wrap(
            children: [
              TextButton(
                onPressed: allSketches.value.isNotEmpty
                    ? () => undoRedoStack.value.undo()
                    : null,
                child: const Text('Undo'),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: undoRedoStack.value._canRedo,
                builder: (_, canRedo, __) {
                  return TextButton(
                    onPressed:
                        canRedo ? () => undoRedoStack.value.redo() : null,
                    child: const Text('Redo'),
                  );
                },
              ),
              TextButton(
                child: const Text('Clear'),
                onPressed: () => undoRedoStack.value.clear(),
              ),
              TextButton(
                //ignore: avoid-passing-async-when-sync-expected
                onPressed: () async {
                  backgroundImage.value =
                      backgroundImage.value != null ? null : await _getImage;
                },
                child: Text(
                  backgroundImage.value == null
                      ? 'Add Background'
                      : 'Remove Background',
                ),
              ),
              TextButton(
                child: const Text('Fork on Github'),
                onPressed: () => _launchUrl(kGithubRepo),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Export',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Row(
            children: [
              SizedBox(
                width: 140,
                child: TextButton(
                  child: const Text('Export PNG'),
                  //ignore: avoid-passing-async-when-sync-expected
                  onPressed: () async {
                    final pngBytes = await getBytes();
                    if (pngBytes != null) await saveFile(pngBytes, 'png');
                  },
                ),
              ),
              SizedBox(
                width: 140,
                child: TextButton(
                  child: const Text('Export JPEG'),
                  //ignore: avoid-passing-async-when-sync-expected
                  onPressed: () async {
                    final pngBytes = await getBytes();
                    if (pngBytes != null) await saveFile(pngBytes, 'jpeg');
                  },
                ),
              ),
            ],
          ),
          // add about me button or follow buttons
          const Divider(),
          Center(
            child: GestureDetector(
              onTap: () => _launchUrl('https://github.com/JideGuru'),
              child: const Text(
                'Made with 💙 by JideGuru',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> saveFile(Uint8List bytes, String ext) async {
    if (kIsWeb) {
      html.AnchorElement()
        ..href = '${Uri.dataFromBytes(bytes, mimeType: 'image/$ext')}'
        ..download = 'FlutterLetsDraw-${DateTime.now().toIso8601String()}.$ext'
        ..style.display = 'none'
        ..click();
    } else {
      await FileSaver.instance.saveFile(
        name: 'FlutterLetsDraw-${DateTime.now().toIso8601String()}.$ext',
        bytes: bytes,
        ext: ext,
        mimeType: ext == 'png' ? MimeType.png : MimeType.jpeg,
      );
    }
  }

  Future<ui.Image> get _getImage async {
    final completer = Completer<ui.Image>();
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (file != null) {
        final filePath = file.files.single.path;
        final bytes = filePath == null
            ? file.files.first.bytes
            : File(filePath).readAsBytesSync();
        if (bytes != null) {
          completer.complete(decodeImageFromList(bytes));
        } else {
          completer.completeError('No image selected');
        }
      }
    } else {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        completer.complete(
          decodeImageFromList(bytes),
        );
      } else {
        completer.completeError('No image selected');
      }
    }

    return completer.future;
  }

  Future<void> _launchUrl(String url) async {
    if (kIsWeb) {
      html.window.open(
        url,
        url,
      );
    } else {
      if (!await launchUrl(Uri.parse(url))) {
        throw Exception('Could not launch $url');
      }
    }
  }

  Future<Uint8List?> getBytes() async {
    final boundary = canvasGlobalKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();

    return pngBytes;
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    this.iconData,
    this.child,
    this.tooltip,
    required this.selected,
    required this.onTap,
  }) : assert(
          child != null || iconData != null,
          '_IconBox child or iconData is null',
        );
  final IconData? iconData;
  final Widget? child;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 35,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? Colors.grey[900]! : Colors.grey,
                width: 1.5,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: Tooltip(
              message: tooltip,
              preferBelow: false,
              child: child ??
                  Icon(
                    iconData,
                    color: selected ? Colors.grey[900] : Colors.grey,
                    size: 20,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

///A data structure for undoing and redoing sketches.
class _UndoRedoStack {
  _UndoRedoStack({
    required this.sketchesNotifier,
    required this.currentSketchNotifier,
  }) {
    _sketchCount = sketchesNotifier.value.length;
    sketchesNotifier.addListener(_sketchesCountListener);
  }

  final ValueNotifier<List<Sketch>> sketchesNotifier;
  final ValueNotifier<Sketch?> currentSketchNotifier;

  ///Collection of sketches that can be redone.
  late final List<Sketch> _redoStack = [];

  ///Whether redo operation is possible.
  ValueNotifier<bool> get canRedo => _canRedo;
  late final ValueNotifier<bool> _canRedo = ValueNotifier(false);

  late int _sketchCount;

  void _sketchesCountListener() {
    if (sketchesNotifier.value.length > _sketchCount) {
      //if a new sketch is drawn,
      //history is invalidated so clear redo stack
      _redoStack.clear();
      _canRedo.value = false;
      _sketchCount = sketchesNotifier.value.length;
    }
  }

  void clear() {
    _sketchCount = 0;
    sketchesNotifier.value = [];
    _canRedo.value = false;
    currentSketchNotifier.value = null;
  }

  void undo() {
    final sketches = List<Sketch>.from(sketchesNotifier.value);
    if (sketches.isNotEmpty) {
      _sketchCount--;
      _redoStack.add(sketches.removeLast());
      sketchesNotifier.value = sketches;
      _canRedo.value = true;
      currentSketchNotifier.value = null;
    }
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final sketch = _redoStack.removeLast();
    _canRedo.value = _redoStack.isNotEmpty;
    _sketchCount++;
    sketchesNotifier.value = [...sketchesNotifier.value, sketch];
  }

  void dispose() {
    sketchesNotifier.removeListener(_sketchesCountListener);
  }
}
