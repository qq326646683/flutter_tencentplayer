import 'package:flutter/material.dart';

class TrianglePainter extends CustomPainter {
  late Paint mPaint;
  final BuildContext mContext;
  TrianglePainter(this.mContext) {
    mPaint = new Paint();
    mPaint.style = PaintingStyle.fill;
    mPaint.color = Color(0x7f000000);
    mPaint.isAntiAlias = true;

  }

  @override
  void paint(Canvas canvas, Size size) {
    Path path = new Path();
    path.moveTo(0, 0);// 此点为多边形的起点
    path.lineTo(6, 6);
    path.lineTo(12, 0);
    path.close();
    canvas.drawPath(path, mPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }


}