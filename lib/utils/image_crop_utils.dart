import 'dart:typed_data';

import 'package:image/image.dart' as img;

class CroppedImageResult {
  CroppedImageResult({required this.bytes, required this.cropBox});

  final Uint8List bytes;
  final Map<String, int> cropBox;
}

class ImageCropUtils {
  ImageCropUtils._();

  static CroppedImageResult? autoCropToAspect(
    Uint8List sourceBytes, {
    double aspectRatio = 3.0,
  }) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) return null;

    final sourceWidth = decoded.width;
    final sourceHeight = decoded.height;
    final currentRatio = sourceWidth / sourceHeight;

    int cropWidth = sourceWidth;
    int cropHeight = sourceHeight;

    if (currentRatio > aspectRatio) {
      cropHeight = sourceHeight;
      cropWidth = (cropHeight * aspectRatio).round();
    } else {
      cropWidth = sourceWidth;
      cropHeight = (cropWidth / aspectRatio).round();
    }

    final offsetX = ((sourceWidth - cropWidth) / 2).round();
    final offsetY = ((sourceHeight - cropHeight) / 2).round();

    final cropped = img.copyCrop(
      decoded,
      x: offsetX,
      y: offsetY,
      width: cropWidth,
      height: cropHeight,
    );

    final encoded = Uint8List.fromList(img.encodeJpg(cropped, quality: 90));

    return CroppedImageResult(
      bytes: encoded,
      cropBox: {
        'x': offsetX,
        'y': offsetY,
        'width': cropWidth,
        'height': cropHeight,
      },
    );
  }
}
