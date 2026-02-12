import 'package:flutter/material.dart';

class AppShadow {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 6,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}
