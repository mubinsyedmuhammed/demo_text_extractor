import 'dart:developer';
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
  // ignore: library_private_types_in_public_api
  _ROISelectionState createState() => _ROISelectionState();
}

class _ROISelectionState extends State<ROISelection> {
  Rect roiRect = Rect.zero;
  Offset _startPoint = Offset.zero;
  late double imageWidth, imageHeight;
  GlobalKey imageKey = GlobalKey();
  Size? displaySize;
  
  // Simplified zoom variables
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    try {
      final image = img.decodeImage(widget.imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      imageWidth = image.width.toDouble();
      imageHeight = image.height.toDouble();
    } catch (e) {
      log('Error initializing ROI selection: $e');
      imageWidth = 0;
      imageHeight = 0;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _updateDisplaySize() {
    final RenderBox? renderBox = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        displaySize = renderBox.size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                onInteractionUpdate: (details) {
                  setState(() {
                    _currentScale = _transformationController.value.getMaxScaleOnAxis();
                  });
                },
                child: GestureDetector(
                  onPanStart: (details) {
                    if (_currentScale <= 1.1) { // Only allow ROI selection when not heavily zoomed
                      _updateDisplaySize();
                      setState(() {
                        _startPoint = details.localPosition;
                        roiRect = Rect.fromPoints(details.localPosition, details.localPosition);
                      });
                    }
                  },
                  onPanUpdate: (details) {
                    if (_currentScale <= 1.1) {
                      setState(() {
                        roiRect = Rect.fromPoints(_startPoint, details.localPosition);
                      });
                    }
                  },
                  onPanEnd: (details) async {
                    if (_currentScale <= 1.1 && roiRect.width > 10 && roiRect.height > 10) {
                      final croppedImageBytes = await _cropImage();
                      if (croppedImageBytes != null) {
                        setState(() {
                          croppedImages = croppedImageBytes;
                        });
                        widget.onROISelected(croppedImageBytes);
                      } else {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to crop the image')),
                        );
                      }
                    }
                  },
                  child: Image.memory(
                    widget.imageBytes,
                    key: imageKey,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (roiRect.width > 0 && roiRect.height > 0 && _currentScale <= 1.1)
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
      ],
    );
  }

  Future<Uint8List?> _cropImage() async {
    try {
      if (displaySize == null) {
        throw Exception('Display size not initialized');
      }
      
      final image = img.decodeImage(widget.imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image for cropping');
      }

      if (roiRect.width < 10 || roiRect.height < 10) {
        throw Exception('Selected area too small');
      }

      // Calculate scaling factors
      double scaleX = imageWidth / displaySize!.width;
      double scaleY = imageHeight / displaySize!.height;

      // Convert display coordinates to actual image coordinates
      int x = (roiRect.left * scaleX).round();
      int y = (roiRect.top * scaleY).round();
      int width = (roiRect.width * scaleX).round();
      int height = (roiRect.height * scaleY).round();

      // Ensure coordinates are within image bounds
      x = x.clamp(0, image.width - 1);
      y = y.clamp(0, image.height - 1);
      width = width.clamp(1, image.width - x);
      height = height.clamp(1, image.height - y);

      log('Cropping at coordinates: x=$x, y=$y, width=$width, height=$height');
      
      final img.Image croppedImage = img.copyCrop(
        image,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      log('Successfully cropped image');
      return Uint8List.fromList(img.encodePng(croppedImage));
    } catch (e) {
      log('Error during crop: $e');
      return null;
    }
  }
}
