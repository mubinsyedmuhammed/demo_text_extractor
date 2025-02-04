// import 'dart:developer';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;

// class ROISelection extends StatefulWidget {
//   final Uint8List imageBytes;
//   final Function(Uint8List) onROISelected;

//   const ROISelection({
//     super.key,
//     required this.imageBytes,
//     required this.onROISelected,
//   });

//   @override
//   // ignore: library_private_types_in_public_api
//   _ROISelectionState createState() => _ROISelectionState();
// }

// class _ROISelectionState extends State<ROISelection> {
//   Rect _roiRect = Rect.zero;
//   Offset _startPoint = Offset.zero;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onPanStart: (details) {
//         setState(() {
//           _startPoint = details.localPosition;
//           _roiRect = Rect.fromPoints(details.localPosition, details.localPosition);
//         });
//       },
//       onPanUpdate: (details) {
//         setState(() {
//           _roiRect = Rect.fromPoints(_startPoint, details.localPosition);
//         });
//       },
//       onPanEnd: (details) {
//         if (_roiRect.width > 10 && _roiRect.height > 10) {
//           final croppedImageBytes = _cropImage();
//           if (croppedImageBytes != null) {
//             widget.onROISelected(croppedImageBytes);
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Failed to crop the image')),
//             );
//           }
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please select a valid ROI')),
//           );
//         }
//       },
//       child: Stack(
//         children: [
//           Image.memory(widget.imageBytes),
//           if (_roiRect.width > 0 && _roiRect.height > 0)
//             Positioned(
//               left: _roiRect.left,
//               top: _roiRect.top,
//               width: _roiRect.width,
//               height: _roiRect.height,
//               child: Container(
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.red, width: 2),
//                   color: Colors.transparent, // Hollow effect
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Uint8List? _cropImage() {
//     final image = img.decodeImage(widget.imageBytes);
//     if (image == null) {
//       log('Failed to decode image');
//       return null;
//     }

//     int x = _roiRect.left.toInt();
//     int y = _roiRect.top.toInt();
//     int width = _roiRect.width.toInt();
//     int height = _roiRect.height.toInt();
    
//     log('$x:$y:$width:$height');
    
//     // Ensure crop dimensions do not exceed the image boundaries
//     x = x.clamp(0, image.width);
//     y = y.clamp(0, image.height);
//     width = width.clamp(0, image.width - x);
//     height = height.clamp(0, image.height - y);

//     log('after : $x:$y:$width:$height');

//     if (width <= 0 || height <= 0) {
//       log('Invalid crop dimensions: $x:$y:$width:$height');
//       return null;
//     }

//     final img.Image croppedImage = img.copyCrop(image, x: x, y: y, width: width, height: height);
//     final croppedImageBytes = Uint8List.fromList(img.encodePng(croppedImage));

//     if (croppedImageBytes.isEmpty) {
//       log('Cropped image is empty');
//       return null;
//     }

//     return croppedImageBytes;
//   }
// }

