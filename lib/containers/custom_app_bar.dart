import 'package:text_extractor/screens/home_screen.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.pink[50],
      centerTitle: true,
      title: GestureDetector(
          onTap: () {
            // Rebuild the HomeScreen when the title is clicked
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyHomePage()),
            );
          },
        child: const Text(
            "Home Screen", 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black
            ),
      )
    ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
