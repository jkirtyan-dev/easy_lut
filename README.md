A dart package to use LUT files.

## Features

 - Parse 1D LUT files
     - Use TITLE line to get title (default is the filename)
 - Parse 3D LUT files
   - Use TITLE line to get title (default is the filename)
   - 3 columns and 6 columns formats are also supported
 - Parse LUT "images"
   - only png
 - Apply LUTs on Images with [image](https://pub.dev/packages/image) package

## Usage

The goal was to make LUT applying simple. So you only have to use about 2 methods.

```dart
import 'package:easy_lut/easy_lut.dart';

void main() async {
  final easyLUT = EasyLUT();
  
  final lut = await easyLUT.parseLUTWithPath('path_of_your_lut.cube');
  final filteredImageData = await easyLUT.applyLUTonPath(lut, 'your_image_path');
  
  print('${lut.title} lut applied on image');
}
```

## Available methods

An EasyLUT object has the following public methods.

```dart
/// Parse LUT data with file path
Future<LUT> parseLUTWithPath(String path)

/// Parse LUT data with file path
Future<LUT> parseLUTWithFile(File file)


/// Apply LUT data on imageData and returns with the result imageData
Uint8List? applyLUT(LUT lut, Uint8List imageData)

///  Apply LUT data on file
/// The original file will not change
/// returns with the result imageData
Future<Uint8List?> applyLUTonFile(LUT lut, File file)

/// Apply LUT data on file path
/// The original file will not change
/// returns with the result imageData
Future<Uint8List?> applyLUTonPath(LUT lut, String path)

/// Converts 3D LUT to image
Uint8List convertLUTtoBMP(ThreeDimensionLUT lut)
```

## Additional information

It's only the minimal functionality I needed at this moment. Feel free to contact me or create tickets on GitHub.
I didn't test it with video stream so I'm not sure it's working fast enough to applying filter on that.