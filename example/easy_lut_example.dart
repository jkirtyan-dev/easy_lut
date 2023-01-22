import 'dart:io';

import 'package:easy_lut/easy_lut.dart';

void main() async {
  final imageData = await File('card_1.png').readAsBytes();

  final lutPaths = [
    'InverseLUT',
    '1DummyLUT',
    'LBK-K-Tone_33.cube',
  ];

  final easyLUT = EasyLUT();

  for (var path in lutPaths) {
    LUT lut;

    try {
      lut = await easyLUT.parseLUTWithPath(path);
    } catch (err) {
      print('ERROR: Skipped $path\n$err');
      continue;
    }

    final fileName = lut.title
        .replaceAll(' ', '_')
        .replaceAll('"', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('-', '_');

    if (lut is ThreeDimensionLUT) {
      final lutBMP = easyLUT.convertLUTtoBMP(lut);
      await File('${fileName}_lut.bmp').writeAsBytes(lutBMP);
    }

    final newImageData = easyLUT.applyLUT(lut, imageData);

    if (newImageData != null) {
      await File('$fileName.png').writeAsBytes(newImageData);
    }
  }
}
