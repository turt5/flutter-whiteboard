// import 'dart:ui';
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:whiteboard/model/_point.dart';
//
// class Draw extends CustomPainter {
//   const Draw({required this.points, required this.originalSize});
//
//   final List<Point> points;
//   final Size originalSize;
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     double scaleX = size.width / originalSize.width;
//     double scaleY = size.height / originalSize.height;
//
//     for (int i = 0; i < points.length - 1; i++) {
//       if (points[i].offset != null && points[i + 1].offset != null) {
//         Offset p1 = Offset(points[i].offset!.dx * scaleX, points[i].offset!.dy * scaleY);
//         Offset p2 = Offset(points[i + 1].offset!.dx * scaleX, points[i + 1].offset!.dy * scaleY);
//
//         Paint paint = Paint()
//           ..color = points[i].isSelected ? Colors.redAccent : points[i].color
//           ..strokeWidth = points[i].isSelected ? 4.0 : 2.0
//           ..strokeCap = StrokeCap.round;
//
//         canvas.drawLine(p1, p2, paint);
//       } else if (points[i].offset != null && points[i + 1].offset == null) {
//         Offset p1 = Offset(points[i].offset!.dx * scaleX, points[i].offset!.dy * scaleY);
//
//         Paint paint = Paint()
//           ..color = points[i].isSelected ? Colors.redAccent : points[i].color
//           ..strokeWidth = points[i].isSelected ? 4.0 : 2.0
//           ..strokeCap = StrokeCap.round;
//
//         canvas.drawPoints(PointMode.points, [p1], paint);
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
