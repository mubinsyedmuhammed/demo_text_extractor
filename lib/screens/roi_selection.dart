// import 'dart:developer';
import 'dart:typed_data';
import 'package:demo_text_extractor/Services/image_uploader.dart';
import 'package:demo_text_extractor/const.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

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

  void _synchronizeTransformation([ScaleEndDetails? details]) {
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

  Matrix4 get _effectiveTransform {
    final matrix = _transformController.value.clone();
    final rotation = widget.rotationNotifier.value * (math.pi / 180);
    final rotationMatrix = Matrix4.rotationZ(rotation);
    return matrix..multiply(rotationMatrix);
  }

  Offset _transformPoint(Offset point, Matrix4 transform) {
    final vector = Vector3(point.dx, point.dy, 0);
    final transformed = transform.perspectiveTransform(vector);
    return Offset(transformed.x, transformed.y);
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

    setState(() {
      roiRect = Rect.fromPoints(_startPoint, localPos);
    });
  }

  Future<Uint8List?> _cropImage() async {
    if (_imageRect == null) return null;
    
    final image = img.decodeImage(widget.imageBytes);
    if (image == null) return null;

    // Get current transformation state
    final transform = _transformController.value;
    final scale = transform.getMaxScaleOnAxis();
    final translation = transform.getTranslation();
    final rotation = widget.rotationNotifier.value;
    
    // Convert ROI coordinates to image space
    final viewToImageTransform = Matrix4.identity()
      ..scale(image.width / _imageRect!.width, image.height / _imageRect!.height);
    
    // Apply all transformations in correct order
    final adjustedRect = _getTransformedRect(
      rect: roiRect,
      scale: scale,
      translation: translation,
      rotation: rotation,
      viewToImage: viewToImageTransform,
    );

    // Ensure coordinates are within bounds
    final x = adjustedRect.left.round().clamp(0, image.width - 1);
    final y = adjustedRect.top.round().clamp(0, image.height - 1);
    final width = adjustedRect.width.round().clamp(1, image.width - x);
    final height = adjustedRect.height.round().clamp(1, image.height - y);

    try {
      // Apply rotation to image first if needed
      final rotatedImage = rotation != 0
          ? img.copyRotate(image, angle: rotation.round())
          : image;

      // Then crop the rotated image
      final croppedImage = img.copyCrop(
        rotatedImage,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      return Uint8List.fromList(img.encodePng(croppedImage));
    } catch (e) {
      debugPrint('Cropping error: $e');
      return null;
    }
  }

  Rect _getTransformedRect({
    required Rect rect,
    required double scale,
    required Vector3 translation,
    required double rotation,
    required Matrix4 viewToImage,
  }) {
    // Adjust for translation and scale
    final unscaledRect = Rect.fromLTWH(
      (rect.left - translation.x) / scale,
      (rect.top - translation.y) / scale,
      rect.width / scale,
      rect.height / scale,
    );

    // Adjust for rotation around center
    final center = unscaledRect.center;
    final rad = rotation * math.pi / 180;
    final cos = math.cos(rad);
    final sin = math.sin(rad);

    List<Offset> corners = [
      unscaledRect.topLeft,
      unscaledRect.topRight,
      unscaledRect.bottomRight,
      unscaledRect.bottomLeft,
    ];

    // Rotate each corner
    corners = corners.map((corner) {
      final dx = corner.dx - center.dx;
      final dy = corner.dy - center.dy;
      return Offset(
        center.dx + (dx * cos - dy * sin),
        center.dy + (dx * sin + dy * cos),
      );
    }).toList();

    // Convert to image coordinates
    corners = corners.map((corner) {
      final vector = viewToImage.transform3(Vector3(corner.dx, corner.dy, 0));
      return Offset(vector.x, vector.y);
    }).toList();

    // Get bounding box of transformed corners
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final corner in corners) {
      minX = math.min(minX, corner.dx);
      minY = math.min(minY, corner.dy);
      maxX = math.max(maxX, corner.dx);
      maxY = math.max(maxY, corner.dy);
    }

    return Rect.fromLTWH(minX, minY, maxX - minX, maxY - minY);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
