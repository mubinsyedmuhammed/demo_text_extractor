import 'dart:developer';
import 'dart:typed_data';
<<<<<<< Updated upstream
import 'package:demo_text_extractor/Services/api_fast.dart';
import 'package:demo_text_extractor/Services/getx.dart';
import 'package:demo_text_extractor/const.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
=======
import 'dart:math' as math;
import 'package:demo_text_extractor/Services/image_uploader.dart';
import 'package:demo_text_extractor/const.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

>>>>>>> Stashed changes

class ROISelection extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List) onROISelected;
<<<<<<< Updated upstream
=======
  final TransformationController? transformationController;
  final ValueNotifier<double> rotationNotifier;
  final Matrix4? initialTransformation;
  final GlobalKey? parentKey;
>>>>>>> Stashed changes

  const ROISelection({
    super.key,
    required this.imageBytes,
    required this.onROISelected,
<<<<<<< Updated upstream
=======
    this.transformationController,
    required this.rotationNotifier,
    this.initialTransformation,
    this.parentKey,
>>>>>>> Stashed changes
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

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
=======
    _transformController = widget.transformationController ?? TransformationController();
    
    if (widget.initialTransformation != null) {
      _transformController.value = widget.initialTransformation!;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateImageRect();
      _synchronizeTransformation();
    });
>>>>>>> Stashed changes
    final image = img.decodeImage(widget.imageBytes);
    if (image != null) {
      imageWidth = image.width.toDouble();
      imageHeight = image.height.toDouble();
<<<<<<< Updated upstream
=======
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
>>>>>>> Stashed changes
    } else {
      imageWidth = 0;
      imageHeight = 0;
    }
  }

<<<<<<< Updated upstream
  void _updateDisplaySize() {
    final RenderBox? renderBox = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
=======


  void _handlePanStart(DragStartDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);
    _calculateImageRect();

    // Simple bounds check
    if (_imageRect != null) {
>>>>>>> Stashed changes
      setState(() {
        displaySize = renderBox.size;
      });
    }
  }
Future<void> _onPanEndHandler(RoiProvider provider) async {
  if (roiRect.width > 10 && roiRect.height > 10) {
    final croppedImageBytes = await _cropImage();
    if (croppedImageBytes != null) {
      widget.onROISelected(croppedImageBytes);

      OCRService apiService = OCRService();
      String? extractedText = await apiService.extractTextFromImageOcr(croppedImageBytes);
      log("Extracted text: $extractedText");

<<<<<<< Updated upstream
      if (extractedText != null && extractedText.isNotEmpty) {
        // Update the corresponding text field in the provider using the field name
        if (selectedField != null) {
          provider.updateField(selectedField!, extractedText); // Update the correct field controller
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to extract text...')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to crop the image')),
=======
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

    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final transform = _transformController.value;

    // Get the selection bounds in local coordinates
    final localRect = _getLocalRect(roiRect, transform);
    
    // Convert to image coordinates
    final imageScale = math.min(
      size.width / image.width,
      size.height / image.height
    );

    final x = ((localRect.left) / imageScale).round().clamp(0, image.width - 1);
    final y = ((localRect.top) / imageScale).round().clamp(0, image.height - 1);
    final width = (localRect.width / imageScale).round().clamp(1, image.width - x);
    final height = (localRect.height / imageScale).round().clamp(1, image.height - y);

    try {
      final rotation = widget.rotationNotifier.value.round();
      final processedImage = rotation != 0 
          ? img.copyRotate(image, angle: rotation)
          : image;

      final croppedImage = img.copyCrop(
        processedImage,
        x: x,
        y: y,
        width: width,
        height: height,
>>>>>>> Stashed changes
      );
    }
<<<<<<< Updated upstream
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a valid ROI')),
=======
  }

  Rect _getLocalRect(Rect rect, Matrix4 transform) {
    final translation = transform.getTranslation();
    final scale = transform.getMaxScaleOnAxis();

    return Rect.fromLTWH(
      (rect.left - translation.x) / scale,
      (rect.top - translation.y) / scale,
      rect.width / scale,
      rect.height / scale,
>>>>>>> Stashed changes
    );
  }
}


  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    return Consumer<RoiProvider>(
      builder: (context, value, child) => 
       Center(
        child: Stack(
          children: [
            GestureDetector(
              onPanStart: (details) {
                _updateDisplaySize();
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
              onPanEnd: (_) => _onPanEndHandler(value), // Handle pan end here
              child: Image.memory(
                widget.imageBytes,
                key: imageKey,
                fit: BoxFit.contain,
              ),
            ),
            if (roiRect.width > 0 && roiRect.height > 0)
              Positioned(
                left: roiRect.left,
                top: roiRect.top,
                width: roiRect.width,
                height: roiRect.height,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
=======
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 4.0,
              scaleEnabled: false,
              panEnabled: false,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: imageWidth / imageHeight,
                    child: RotationAwareImage(
                      imageBytes: widget.imageBytes,
                      rotationNotifier: widget.rotationNotifier,
                      key: imageKey,
                    ),
                  ),
                ),
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
                    viewportSize: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                ),
              ),
            ),
          ],
        );
      },
>>>>>>> Stashed changes
    );
  }

  Future<Uint8List?> _cropImage() async {
    if (displaySize == null) return null;

<<<<<<< Updated upstream
    final image = img.decodeImage(widget.imageBytes);
    if (image == null) return null;

    // Calculate scaling factors
    double scaleX = imageWidth / displaySize!.width;
    double scaleY = imageHeight / displaySize!.height;
=======
// Simplify the ROISelectionPainter
class ROISelectionPainter extends CustomPainter {
  final Rect selectionRect;
  final Rect? imageRect;
  final Size viewportSize;

  ROISelectionPainter({
    required this.selectionRect,
    this.imageRect,
    required this.viewportSize,
  });
>>>>>>> Stashed changes

    // Convert display coordinates to actual image coordinates
    int x = (roiRect.left * scaleX).round();
    int y = (roiRect.top * scaleY).round();
    int width = (roiRect.width * scaleX).round();
    int height = (roiRect.height * scaleY).round();

<<<<<<< Updated upstream
    // Ensure coordinates are within image bounds
    x = x.clamp(0, image.width - 1);
    y = y.clamp(0, image.height - 1);
    width = width.clamp(1, image.width - x);
    height = height.clamp(1, image.height - y);

    final img.Image croppedImage = img.copyCrop(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    return Uint8List.fromList(img.encodePng(croppedImage));
=======
    // Add semi-transparent overlay
    canvas.drawRect(
      Offset.zero & size,
      // ignore: deprecated_member_use
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // Draw selection rectangle with clear interior
    if (selectionRect != Rect.zero) {
      canvas.drawRect(
        selectionRect,
        Paint()
          // ignore: deprecated_member_use
          ..color = Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.fill,
      );
      
      canvas.drawRect(
        selectionRect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      _drawCornerMarkers(canvas);
    }
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
>>>>>>> Stashed changes
  }
}
