import 'dart:io';

import 'package:easy_lut/easy_lut.dart';

void main() async {
  final imageData = await File('card_1.png').readAsBytes();

  final lutPaths = [
    'neutral-lut.png',
    'InverseLUT',
    '1DummyLUT',
    'LBK-K-Tone_33.cube',
  ];

  final easyLUT = EasyLUT();

  for (var path in lutPaths) {
    final lut = await easyLUT.parseLUTWithPath(path);

    final newImageData = easyLUT.applyLUT(lut, imageData);

    if (newImageData != null) {
      final fileName = lut.title
          .replaceAll(' ', '_')
          .replaceAll('"', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .replaceAll('-', '_');

      await File('$fileName.png').writeAsBytes(newImageData);
    }
  }
}
