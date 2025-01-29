// ignore: depend_on_referenced_packages
import 'package:text_extractor/services/text_form.dart';
import 'package:flutter/material.dart';

class LeftContainer extends StatelessWidget {
  const LeftContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: CustomForm(),
      ),
    );
  }
}
