import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ROISelection extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List) onROISelected;

  const ROISelection({
    super.key,
    required this.imageBytes,
    required this.onROISelected,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ROISelectionState createState() => _ROISelectionState();
}

class _ROISelectionState extends State<ROISelection> {
  Rect roiRect = Rect.zero;
  Offset _startPoint = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _startPoint = details.localPosition;
                roiRect = Rect.fromPoints(details.localPosition, details.localPosition);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                roiRect = Rect.fromPoints(_startPoint, details.localPosition);
              });
            },
            onPanEnd: (details) async {
              if (roiRect.width > 10 && roiRect.height > 10) {
                final croppedImageBytes = await _cropImage();
                if (croppedImageBytes != null) {
                  widget.onROISelected(croppedImageBytes);
                } else {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to crop the image')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a valid ROI')),
                );
              }
            },
            child: Image.memory(widget.imageBytes),
          ),
          if (roiRect.width > 0 && roiRect.height > 0)
            Positioned(
              left: roiRect.left,
              top: roiRect.top,
              width: roiRect.width,
              height: roiRect.height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<Uint8List?> _cropImage() async {
  final image = img.decodeImage(widget.imageBytes);
    if (image == null) {
      log('Failed to decode image');
      return null;
    }

    // Get the original image dimensions
    int imageWidth = image.width;
    int imageHeight = image.height;

    // Map the ROI coordinates directly to the image size
    int x = roiRect.left.toInt();
    int y = roiRect.top.toInt();
    int width = roiRect.width.toInt();
    int height = roiRect.height.toInt();

    log('Selected ROI (original image): $x:$y:$width:$height');

    // Clamp values to avoid errors (ensure they are within image bounds)
    x = x.clamp(0, imageWidth);
    y = y.clamp(0, imageHeight);
    width = width.clamp(0, imageWidth - x);
    height = height.clamp(0, imageHeight - y);

    if (width <= 0 || height <= 0) {
      log('Invalid crop dimensions: $x:$y:$width:$height');
      return null;
    }

    // Crop the image based on the original dimensions
    final img.Image croppedImage = img.copyCrop(image, x: x, y: y, width: width, height: height);

    // Convert to PNG format
    return Uint8List.fromList(img.encodePng(croppedImage));
  }

}
