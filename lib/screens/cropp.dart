import 'package:flutter/material.dart';

class CroppedImageShow extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final image;
  const CroppedImageShow({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Image.memory(image),
      ),
    );
  }
}