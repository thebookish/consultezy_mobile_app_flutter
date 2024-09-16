// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Button extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const Button({
    Key? key,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0), // Set the border radius
            color: Color(0xff00adb5)),
        child: Container(
          constraints: BoxConstraints(minHeight: 50.0), // Set a minimum height
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                fontFamily: GoogleFonts.poppins().fontFamily),
          ),
        ),
      ),
    );
  }
}
