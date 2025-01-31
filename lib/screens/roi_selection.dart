import 'dart:developer';
import 'dart:typed_data';
import 'package:demo_text_extractor/Services/api_fast.dart';
import 'package:demo_text_extractor/Services/getx.dart';
import 'package:demo_text_extractor/const.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    final image = img.decodeImage(widget.imageBytes);
    if (image != null) {
      imageWidth = image.width.toDouble();
      imageHeight = image.height.toDouble();
    } else {
      imageWidth = 0;
      imageHeight = 0;
    }
  }

  void _updateDisplaySize() {
    final RenderBox? renderBox = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
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
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a valid ROI')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
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
    );
  }

  Future<Uint8List?> _cropImage() async {
    if (displaySize == null) return null;

    final image = img.decodeImage(widget.imageBytes);
    if (image == null) return null;

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

    final img.Image croppedImage = img.copyCrop(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    return Uint8List.fromList(img.encodePng(croppedImage));
  }
}
