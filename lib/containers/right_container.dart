// ignore: unused_import
import 'package:text_extractor/Services/image_uploader.dart';
import 'package:flutter/material.dart';

class RightContainer extends StatelessWidget {
  const RightContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: ImageUploader(),
      ),
    );
  }
}
