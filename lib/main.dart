import 'package:flutter/material.dart';
import 'package:text_extractor/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.teal,
        canvasColor: Colors.grey[200],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}