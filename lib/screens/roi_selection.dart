// import 'dart:developer';
import 'dart:typed_data';
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
  final double rotation;

  const ROISelection({
    super.key,
    required this.imageBytes,
    required this.onROISelected,
    this.transformationController,
    this.rotation = 0,
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
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.5,
                maxScale: 4.0,
                onInteractionEnd: (details) {
                  if (widget.transformationController != null) {
                    widget.transformationController!.value = _transformController.value;
                  }
                },
                child: Transform.rotate(
                  angle: widget.rotation * 3.14159 / 180,
                  child: Image.memory(
                    widget.imageBytes,
                    key: imageKey,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (_imageRect != null)
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: (details) {
                    final matrix = _transformController.value;
                    final adjustedPosition = _getAdjustedPosition(details.localPosition, matrix);
                    _handlePanStart(DragStartDetails(
                      localPosition: adjustedPosition,
                      globalPosition: details.globalPosition,
                    ));
                  },
                  onPanUpdate: (details) {
                    final matrix = _transformController.value;
                    final adjustedPosition = _getAdjustedPosition(details.localPosition, matrix);
                    _handlePanUpdate(DragUpdateDetails(
                      localPosition: adjustedPosition,
                      globalPosition: details.globalPosition,
                      delta: details.delta,
                    ));
                  },
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
                      transform: _transformController.value,
                      rotation: widget.rotation,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Offset _getAdjustedPosition(Offset position, Matrix4 transform) {
    final scale = transform.getMaxScaleOnAxis();
    final translation = Vector3(transform.getTranslation().x, transform.getTranslation().y, 0.0);
    
    return Offset(
      (position.dx - translation.x) / scale,
      (position.dy - translation.y) / scale,
    );
  }

  Future<Uint8List?> _cropImage() async {
    if (_imageRect == null) return null;
    
    final image = img.decodeImage(widget.imageBytes);
    if (image == null) return null;

    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();

    // Adjust selection coordinates based on current transform
    final adjustedRect = Rect.fromLTRB(
      (roiRect.left - translation.x) / scale,
      (roiRect.top - translation.y) / scale,
      (roiRect.right - translation.x) / scale,
      (roiRect.bottom - translation.y) / scale,
    );

    // Calculate image coordinates
    final imageRect = _imageRect!;
    final relativeX = (adjustedRect.left - imageRect.left) / imageRect.width;
    final relativeY = (adjustedRect.top - imageRect.top) / imageRect.height;
    final relativeWidth = adjustedRect.width / imageRect.width;
    final relativeHeight = adjustedRect.height / imageRect.height;

    // Convert to pixel coordinates
    final x = (relativeX * image.width).round().clamp(0, image.width - 1);
    final y = (relativeY * image.height).round().clamp(0, image.height - 1);
    final width = (relativeWidth * image.width).round().clamp(1, image.width - x);
    final height = (relativeHeight * image.height).round().clamp(1, image.height - y);

    try {
      final croppedImage = img.copyCrop(
        image,
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

  @override
  void dispose() {
    if (widget.transformationController == null) {
      _transformController.dispose();
    }
    super.dispose();
  }
}

class ROISelectionPainter extends CustomPainter {
  final Rect selectionRect;
  final Rect? imageRect;
  final Matrix4? transform;
  final double rotation;

  ROISelectionPainter({
    required this.selectionRect,
    this.imageRect,
    this.transform,
    this.rotation = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect == null) return;

    if (transform != null) {
      canvas.save();
      canvas.transform(transform!.storage);
    }

    // Draw only the selection border, no overlay
    canvas.drawRect(
      selectionRect,
      Paint()
        // ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Draw corner markers
    const double markerSize = 10.0;
    final markerPaint = Paint()
      // ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw corner markers at selection corners
    void drawCornerMarker(Offset corner, bool isLeft, bool isTop) {
      canvas.drawLine(
        corner,
        corner.translate(isLeft ? markerSize : -markerSize, 0),
        markerPaint,
      );
      canvas.drawLine(
        corner,
        corner.translate(0, isTop ? markerSize : -markerSize),
        markerPaint,
      );
    }

    // Draw all corners
    drawCornerMarker(selectionRect.topLeft, true, true);
    drawCornerMarker(selectionRect.topRight, false, true);
    drawCornerMarker(selectionRect.bottomLeft, true, false);
    drawCornerMarker(selectionRect.bottomRight, false, false);

    if (transform != null) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ROISelectionPainter oldDelegate) {
    return selectionRect != oldDelegate.selectionRect;
  }
}
