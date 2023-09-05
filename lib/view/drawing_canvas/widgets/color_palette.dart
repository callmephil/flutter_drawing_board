import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

class ColorPalette extends HookWidget {
  const ColorPalette({
    super.key,
    required this.selectedColor,
  });
  final ValueNotifier<Color> selectedColor;

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      Colors.black,
      Colors.white,
      ...Colors.primaries,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final Color color in colors)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => selectedColor.value = color,
                  child: SizedBox.square(
                    dimension: 35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: selectedColor.value == color
                              ? Colors.blue
                              : Colors.grey,
                          width: 1.5,
                        ),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 35,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selectedColor.value,
                  border: Border.all(color: Colors.blue, width: 1.5),
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showColorWheel<AlertDialog>(context, selectedColor);
                },
                child: SvgPicture.asset(
                  'assets/svgs/color_wheel.svg',
                  height: 35,
                  width: 35,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<T?> showColorWheel<T>(
    BuildContext context,
    ValueNotifier<Color> color,
  ) {
    return showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: color.value,
              onColorChanged: (value) {
                color.value = value;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
