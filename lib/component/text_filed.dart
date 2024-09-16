// ignore_for_file: prefer_const_constructors, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextFields extends StatelessWidget {
  final String Labeltext;
  final bool isObsecure;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const TextFields({
    Key? key,
    required this.Labeltext,
    required this.isObsecure,
    required this.controller,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isObsecure,
      decoration: InputDecoration(
        labelText: Labeltext,
        labelStyle: TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff00adb5),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(20)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff00adb5), width: 2.0),
            borderRadius: BorderRadius.circular(20)),
      ),
      style: GoogleFonts.poppins(),
      validator: validator,
    );
  }
}
