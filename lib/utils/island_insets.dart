import 'package:flutter/painting.dart';

Rect getHoangSaInsetRect(Size size) {
  const double width = 100.0;
  const double height = 85.0;
  const double rightMargin = 10.0;
  const double bottomMargin = 10.0;
  const double gap = 10.0;
  
  final double x = size.width - width - rightMargin;
  final double y = size.height - (height * 2) - bottomMargin - gap;
  return Rect.fromLTWH(x, y, width, height);
}

Rect getTruongSaInsetRect(Size size) {
  const double width = 100.0;
  const double height = 85.0;
  const double rightMargin = 10.0;
  const double bottomMargin = 10.0;
  
  final double x = size.width - width - rightMargin;
  final double y = size.height - height - bottomMargin;
  return Rect.fromLTWH(x, y, width, height);
}
