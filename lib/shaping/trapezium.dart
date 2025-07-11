import 'package:flutter/material.dart';
import 'dart:math';

class TrapeziumClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0); // Titik kiri atas
    path.lineTo(size.width, 0); // Titik kanan atas
    path.lineTo(size.width * 0.8, size.height); // Titik kanan bawah lebih ke dalam
    path.lineTo(size.width * 0.2, size.height); // Titik kiri bawah lebih ke dalam
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}