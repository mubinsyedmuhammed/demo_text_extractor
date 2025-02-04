// import 'dart:developer';
import 'dart:typed_data';
import 'package:demo_text_extractor/Services/image_uploader.dart';
import 'package:demo_text_extractor/Services/const.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
// ignore: depend_on_referenced_packages

class ROISelection extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List) onROISelected;
  final TransformationController? transformationController;
  final ValueNotifier<double> rotationNotifier;

  const ROISelection({
    super.key,
    required this.imageBytes,
    required this.onROISelected,
    this.transformationController,
    required this.rotationNotifier,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ROISelectionState createState() => _ROISelectionState();
}

class _ROISelectionState extends State<ROISelection> {
  Rect roiRect = Rect.zero;
  Offset _startPoint = Offset.zero;
  late double imageWidth, imageHeight;
  GlobalKey imageKey = GlobalKey();
  Size? displaySize;
  Rect? _imageRect;
  late final TransformationController _transformController;

  @override
  void initState() {
    super.initState();
    _transformController = widget.transformationController ?? TransformationController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateImageRect();
      _synchronizeTransformation();
    });
    final image = img.decodeImage(widget.imageBytes);
    if (image != null) {
      imageWidth = image.width.toDouble();
      imageHeight = image.height.toDouble();
    }
  }

  void _synchronizeTransformation() {
    if (widget.transformationController != null) {
      _transformController.value = widget.transformationController!.value;
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



  void _handlePanStart(DragStartDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);
    _calculateImageRect();

    // Simple bounds check
    if (_imageRect != null) {
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

    // Constrain selection within image bounds
    final constrainedPos = Offset(
      localPos.dx.clamp(_imageRect!.left, _imageRect!.right),
      localPos.dy.clamp(_imageRect!.top, _imageRect!.bottom),
    );

    setState(() {
      roiRect = Rect.fromPoints(_startPoint, constrainedPos)
          .intersect(_imageRect!); // Ensure selection stays within image bounds
    });
  }

  Future<Uint8List?> _cropImage() async {
    if (_imageRect == null) return null;
    
    final image = img.decodeImage(widget.imageBytes);
    if (image == null) return null;

    try {
      // Calculate relative coordinates within the image bounds
      final relativeX = (roiRect.left - _imageRect!.left) / _imageRect!.width;
      final relativeY = (roiRect.top - _imageRect!.top) / _imageRect!.height;
      final relativeWidth = roiRect.width / _imageRect!.width;
      final relativeHeight = roiRect.height / _imageRect!.height;

      // Convert to actual image coordinates
      final x = (relativeX * image.width).round();
      final y = (relativeY * image.height).round();
      final width = (relativeWidth * image.width).round();
      final height = (relativeHeight * image.height).round();

      // Crop the image
      final croppedImage = img.copyCrop(
        image,
        x: x.clamp(0, image.width - 1),
        y: y.clamp(0, image.height - 1),
        width: width.clamp(1, image.width - x),
        height: height.clamp(1, image.height - y),
      );

      return Uint8List.fromList(img.encodePng(croppedImage));
    } catch (e) {
      debugPrint('Cropping error: $e');
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
    fit:   StackFit.expand,
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.5,
          maxScale: 4.0,
          child: RotationAwareImage(
            imageBytes: widget.imageBytes,
            rotationNotifier: widget.rotationNotifier,
            key: imageKey,
          ),
        ),
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
  }

  @override
  void dispose() {
    if (widget.transformationController == null) {
      _transformController.dispose();
    }
    super.dispose();
  }
}

// Simplify the ROISelectionPainter
class ROISelectionPainter extends CustomPainter {
  final Rect selectionRect;
  final Rect? imageRect;

  ROISelectionPainter({
    required this.selectionRect,
    this.imageRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect == null) return;

    // Draw selection rectangle
    canvas.drawRect(
      selectionRect,
      Paint()
        // ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Draw corner markers
    _drawCornerMarkers(canvas);
  }

  void _drawCornerMarkers(Canvas canvas) {
    const markerSize = 10.0;
    final paint = Paint()
      // ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Helper function to draw corner markers
    void drawCorner(Offset corner, bool isLeft, bool isTop) {
      canvas.drawLine(
        corner,
        corner.translate(isLeft ? markerSize : -markerSize, 0),
        paint,
      );
      canvas.drawLine(
        corner,
        corner.translate(0, isTop ? markerSize : -markerSize),
        paint,
      );
    }

    // Draw all corners
    drawCorner(selectionRect.topLeft, true, true);
    drawCorner(selectionRect.topRight, false, true);
    drawCorner(selectionRect.bottomLeft, true, false);
    drawCorner(selectionRect.bottomRight, false, false);
  }

  @override
  bool shouldRepaint(ROISelectionPainter oldDelegate) {
    return selectionRect != oldDelegate.selectionRect;
  }
}
