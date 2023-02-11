import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart';

enum LUTType { oneDimension, threeDimensions }

typedef OneDimensionData = List<int>;
typedef ThreeDimensionData = List<List<List<int>>>;

abstract class LUT<D> {
  final String title;
  final D data;

  LUT(this.title, this.data);

  LUTType get _dataType =>
      data is OneDimensionData ? LUTType.oneDimension : LUTType.threeDimensions;
}

class OneDimensionLUT extends LUT<OneDimensionData> {
  OneDimensionLUT(super.title, super.data);
}

class ThreeDimensionLUT extends LUT<ThreeDimensionData> {
  ThreeDimensionLUT(super.title, super.data);
}

class EasyLUT {
  /// Parse LUT data with file path
  Future<LUT> parseLUTWithPath(String path) => parseLUTWithFile(File(path));

  /// Parse LUT data with file path
  Future<LUT> parseLUTWithFile(File file) async {
    LUTType? type;
    int firstDataIndex = 0;
    int size = -1;
    String title = _titleFromPath(file.path);

    List<String> lines;

    if (file.path.endsWith('.png') || file.path.endsWith('.bmp')) {
      lines = await _convertLUTImage(file);
    } else {
      lines = await file.readAsLines();
    }
    final n = lines.length;

    while (type == null && firstDataIndex < n) {
      final line = lines[firstDataIndex];

      if (_isLineSeems1DLUTData(line)) {
        type = LUTType.oneDimension;
      } else if (_isLineSeems3DLUTData(line)) {
        type = LUTType.threeDimensions;
      } else {
        if (line.startsWith('LUT_3D_SIZE') || line.startsWith('LUT_1D_SIZE')) {
          size = int.parse(line.split(' ')[1]);
        } else if (line.startsWith('TITLE')) {
          final t = line.split(' ').sublist(1).join(' ');

          if (t.trim().isNotEmpty) {
            title = t.trim();
          }
        }

        firstDataIndex += 1;
      }
    }

    if (type == LUTType.oneDimension) {
      final lutData = lines.map((e) => int.parse(e)).toList();

      return OneDimensionLUT(title, lutData);
    } else if (type == LUTType.threeDimensions) {
      return _parse3DLUT(title, size, lines.sublist(firstDataIndex));
    }

    throw ArgumentError();
  }

  String _titleFromPath(String path) {
    List<String> parts;

    if (Platform.isWindows) {
      parts = path.split('\\');
    } else {
      parts = path.split('/');
    }

    return parts.last.split('.').first;
  }

  ThreeDimensionLUT _parse3DLUT(String title, int size, List<String> lines) {
    List<List<List<int>>> lutData = List.generate(
        size, (_) => List.generate(size, (_) => List.generate(size, (_) => 0)));

    int i = 0;
    for (int x = 0; x < size; ++x) {
      for (int y = 0; y < size; ++y) {
        for (int z = 0; z < size; ++z, ++i) {
          final line = lines[i];

          final values = line.split(' ');

          if (values.length == 3) {
            final r = (double.parse(values[0]) * 255).round();
            final g = (double.parse(values[1]) * 255).round();
            final b = (double.parse(values[2]) * 255).round();

            lutData[x][y][z] = _color(r, g, b);
          } else if (values.length == 6) {
            final r = (double.parse(values[0]) * 255).round();
            final g = (double.parse(values[1]) * 255).round();
            final b = (double.parse(values[2]) * 255).round();

            final R = (double.parse(values[3]) * 255).round();
            final G = (double.parse(values[4]) * 255).round();
            final B = (double.parse(values[5]) * 255).round();

            lutData[r][g][b] = _color(R, G, B);
          }
        }
      }
    }

    return ThreeDimensionLUT(title, lutData);
  }

  bool _isLineSeems1DLUTData(String line) => int.tryParse(line) != null;
  bool _isLineSeems3DLUTData(String line) =>
      line.split(' ').every((n) => double.tryParse(n.trim()) != null);

  /// Apply LUT data on imageData and returns with the result imageData
  Uint8List? applyLUT(LUT lut, Uint8List imageData) {
    Image? image = decodeImage(imageData);

    if (image == null) return null;

    image = applyLUTOnImage(lut, image);

    return encodePng(image);
  }

  /// Apply LUT data on image and returns with the result image
  Image applyLUTOnImage(LUT lut, Image image) {
    if (lut._dataType == LUTType.oneDimension) {
      return _apply1DLUT(lut as OneDimensionLUT, image);
    }

    return _apply3DLUT(lut as ThreeDimensionLUT, image);
  }

  /// Apply LUT data on file
  /// The original file will not change
  /// returns with the result imageData
  Future<Uint8List?> applyLUTonFile(LUT lut, File file) =>
      file.readAsBytes().then((data) => applyLUT(lut, data));

  /// Apply LUT data on file path
  /// The original file will not change
  /// returns with the result imageData
  Future<Uint8List?> applyLUTonPath(LUT lut, String path) =>
      applyLUTonFile(lut, File(path));

  Image _apply1DLUT(OneDimensionLUT lut, Image image) {
    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        final color = image.getPixel(x, y);

        final int r = lut.data[color.r.toInt()];
        final int g = lut.data[color.g.toInt()];
        final int b = lut.data[color.b.toInt()];
        final int a = color.a.toInt();

        image.setPixelRgba(x, y, r, g, b, a);
      }
    }

    return image;
  }

  Image _apply3DLUT(ThreeDimensionLUT lut, Image image) {
    final size = lut.data.length;

    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        final color = image.getPixel(x, y);

        final int r = (color.r * ((size - 1) / 255)).toInt();
        final int g = (color.g * ((size - 1) / 255)).toInt();
        final int b = (color.b * ((size - 1) / 255)).toInt();

        final lutColor = lut.data[b][g][r];
        final R = _red(lutColor);
        final G = _green(lutColor);
        final B = _blue(lutColor);

        image.setPixel(x, y, ColorRgb8(R, G, B));
      }
    }

    return image;
  }

  int _color(int r, int g, int b) => (r << 16) | (g << 8) | b;
  int _red(int color) => (color >> 16) & 0xFF;
  int _green(int color) => (color >> 8) & 0xFF;
  int _blue(int color) => color & 0xFF;

  Future<List<String>> _convertLUTImage(File file) async {
    final image = await decodeImageFile(file.path);

    if (image == null) return [];
    if (image.height != image.width) return [];

    final imageSize = image.width;
    final size = pow(imageSize, 2 / 3.0).round();

    final lines = [
      'TITLE ${_titleFromPath(file.path)}',
      'LUT_3D_SIZE $size',
    ];

    for (int j = 0; j < imageSize; j += size) {
      for (int i = 0; i < imageSize; i += size) {
        for (int y = 0; y < size; ++y) {
          for (int x = 0; x < size; ++x) {
            final color = image.getPixel(i + x, j + y);

            lines.add(
                '${color.rNormalized.toStringAsFixed(6)} ${color.gNormalized.toStringAsFixed(6)} ${color.bNormalized.toStringAsFixed(6)}');
          }
        }
      }
    }

    return lines;
  }

  /// Converts 3D LUT to image
  Uint8List convertLUTtoBMP(ThreeDimensionLUT lut) {
    final lutSize = lut.data.length;

    final imageSize = pow(lutSize, 3 / 2.0).ceil();
    final image = Image(width: imageSize, height: imageSize);

    int x = 0;
    int y = 0;

    final squareCount = sqrt(lutSize).round();
    for (int i = 0; i < lutSize; ++i) {
      for (int j = 0; j < lutSize; ++j) {
        for (int k = 0; k < lutSize; ++k) {
          final color = lut.data[i][j][k];

          x = (i % squareCount) * lutSize + k;
          y = (i ~/ squareCount) * lutSize + j;

          if (x < imageSize && y < imageSize) {
            image.setPixelRgb(x, y, _red(color), _green(color), _blue(color));
          }
        }
      }
    }

    return encodeBmp(image);
  }
}
