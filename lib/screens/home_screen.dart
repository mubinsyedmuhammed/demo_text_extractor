import 'package:text_extractor/containers/custom_app_bar.dart';
import 'package:text_extractor/containers/left_container.dart';
import 'package:text_extractor/containers/right_container.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Row(
        children: const [
          Expanded(
            flex: 1,
            child: LeftContainer(),
          ),
          Expanded(
            flex: 2,
            child: RightContainer(),
          ),
        ],
      ),
    );
  }
}


