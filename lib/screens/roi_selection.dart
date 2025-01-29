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
  Rect _roiRect = Rect.zero;
  bool _isSelecting = false;
  Offset _startPoint = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isSelecting = true;
          _startPoint = details.localPosition;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _roiRect = Rect.fromPoints(
            _startPoint,
            details.localPosition,
          );
        });
      },
      onPanEnd: (details) {
        setState(() {
          _isSelecting = false;
        });
        if (_roiRect.width > 0 && _roiRect.height > 0) {
          widget.onROISelected(_cropImage());
        }
      },
      child: Stack(
        children: [
          Image.memory(widget.imageBytes),
          if (_isSelecting)
            Positioned.fromRect(
              rect: _roiRect,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Uint8List _cropImage() {
  final img.Image image = img.decodeImage(widget.imageBytes)!;

  // Calculate the cropping area based on the selected ROI rect
  final int x = _roiRect.left.toInt();
  final int y = _roiRect.top.toInt();
  final int width = _roiRect.width.toInt();
  final int height = _roiRect.height.toInt();

  final img.Image croppedImage = img.copyCrop(image, x: x, y: y, width: width, height: height);

  // Encode the cropped image back to Uint8List
  return Uint8List.fromList(img.encodeJpg(croppedImage));
}
}
