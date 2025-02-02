// import 'dart:developer';
import 'dart:math';
import 'dart:typed_data';
import 'package:demo_text_extractor/const.dart';
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
  _ROISelectionState createState() => _ROISelectionState();
}

class _ROISelectionState extends State<ROISelection> {
  Rect roiRect = Rect.zero;
  Offset _startPoint = Offset.zero;
  late double imageWidth, imageHeight;
  GlobalKey imageKey = GlobalKey();
  Size? displaySize;
  Rect? _imageRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateImageRect();
    });
    final image = img.decodeImage(widget.imageBytes);
    if (image != null) {
      imageWidth = image.width.toDouble();
      imageHeight = image.height.toDouble();
    }
  }

  void _calculateImageRect() {
    final RenderBox? box = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    final imageAspectRatio = imageWidth / imageHeight;
    final screenAspectRatio = size.width / size.height;

    double actualWidth, actualHeight, xOffset, yOffset;

    if (imageAspectRatio > screenAspectRatio) {
      actualWidth = size.width;
      actualHeight = actualWidth / imageAspectRatio;
      xOffset = 0;
      yOffset = (size.height - actualHeight) / 2;
    } else {
      actualHeight = size.height;
      actualWidth = actualHeight * imageAspectRatio;
      xOffset = (size.width - actualWidth) / 2;
      yOffset = 0;
    }

    setState(() {
      _imageRect = Rect.fromLTWH(xOffset, yOffset, actualWidth, actualHeight);
      displaySize = Size(actualWidth, actualHeight);
    });
  }

  Offset _constrainToImage(Offset point) {
    if (_imageRect == null) return point;
    return Offset(
      point.dx.clamp(_imageRect!.left, _imageRect!.right),
      point.dy.clamp(_imageRect!.top, _imageRect!.bottom),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);
    _calculateImageRect(); // Update image rect on start

    if (_imageRect?.contains(localPos) ?? false) {
      setState(() {
        _startPoint = localPos;
        roiRect = Rect.fromPoints(localPos, localPos);
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_imageRect == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);
    
    // Constrain to image bounds
    final constrainedPos = Offset(
      localPos.dx.clamp(_imageRect!.left, _imageRect!.right),
      localPos.dy.clamp(_imageRect!.top, _imageRect!.bottom),
    );

    setState(() {
      roiRect = Rect.fromPoints(_startPoint, constrainedPos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Image display
            Positioned.fill(
              child: Image.memory(
                widget.imageBytes,
                key: imageKey,
                fit: BoxFit.contain,
              ),
            ),
            // Selection overlay
            Positioned.fill(
              child: GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: (details) async {
                  if (roiRect.width > 10 && roiRect.height > 10) {
                    final croppedImageBytes = await _cropImage();
                    if (croppedImageBytes != null) {
                      setState(() {
                        croppedImages = croppedImageBytes;
                      });
                      widget.onROISelected(croppedImageBytes);
                    }
                  }
                },
                child: CustomPaint(
                  painter: ROISelectionPainter(
                    selectionRect: roiRect,
                    imageRect: _imageRect,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Uint8List?> _cropImage() async {
    if (_imageRect == null) return null;
    
    final image = img.decodeImage(widget.imageBytes);
    if (image == null) return null;

    // Calculate relative coordinates within the image
    final imageSpace = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    
    final relativeRect = Rect.fromLTRB(
      ((roiRect.left - _imageRect!.left) / _imageRect!.width * image.width).clamp(0, image.width.toDouble()),
      ((roiRect.top - _imageRect!.top) / _imageRect!.height * image.height).clamp(0, image.height.toDouble()),
      ((roiRect.right - _imageRect!.left) / _imageRect!.width * image.width).clamp(0, image.width.toDouble()),
      ((roiRect.bottom - _imageRect!.top) / _imageRect!.height * image.height).clamp(0, image.height.toDouble()),
    );

    // Ensure valid crop dimensions
    final cropX = relativeRect.left.round();
    final cropY = relativeRect.top.round();
    final cropWidth = (relativeRect.width).round().clamp(1, image.width - cropX);
    final cropHeight = (relativeRect.height).round().clamp(1, image.height - cropY);

    debugPrint('Cropping at: x=$cropX, y=$cropY, width=$cropWidth, height=$cropHeight');

    try {
      final croppedImage = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      return Uint8List.fromList(img.encodePng(croppedImage));
    } catch (e) {
      debugPrint('Cropping error: $e');
      return null;
    }
  }
}

class ROISelectionPainter extends CustomPainter {
  final Rect selectionRect;
  final Rect? imageRect;

  ROISelectionPainter({required this.selectionRect, this.imageRect});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect == null) return;

    // Draw semi-transparent overlay
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw overlay excluding selection
    canvas.drawRect(imageRect!, paint);
    canvas.drawRect(
      selectionRect,
      Paint()..blendMode = BlendMode.clear,
    );

    // Draw selection border
    canvas.drawRect(
      selectionRect,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(ROISelectionPainter oldDelegate) {
    return selectionRect != oldDelegate.selectionRect;
  }
}
