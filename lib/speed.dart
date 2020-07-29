import 'package:flutter/material.dart';
import 'dart:math';

class SpeedPainter extends CustomPainter {
  Color defaultCircleColor;
  Color percentageCompletedCircleColor;
  double completedPercentage;
  double circleWidth;


  SpeedPainter({this.defaultCircleColor,this.percentageCompletedCircleColor,this.completedPercentage,this.circleWidth});
  
  getPaint(Color color){return Paint()
  ..color=color
  ..strokeCap=StrokeCap.round
  ..style=PaintingStyle.stroke
  
  ..strokeWidth=circleWidth;}


  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0.0, 0.0, size.width, size.height);
     
   final gradient = SweepGradient(
      startAngle:-pi,
      endAngle: pi-0.6,
      tileMode: TileMode.repeated,
      colors: [ Colors.blue[400],Colors.orange[400], Colors.redAccent],
    );
       final paint =  Paint()
      ..shader = gradient.createShader(rect)
      ..strokeCap = StrokeCap.round // StrokeCap.round is not recommended.
      ..style = PaintingStyle.stroke
      ..strokeWidth = circleWidth;
    Paint defaultCirclePaint=getPaint(defaultCircleColor);
    Paint progressCirclePaint=getPaint(percentageCompletedCircleColor);
    Offset center= Offset(size.width/2,size.height/2);
    double radius=160;
    canvas.drawCircle(center,radius,defaultCirclePaint);  
    double arcAngle=2*pi*(completedPercentage/100);
    canvas.drawArc(Rect.fromCircle(center:center,radius:radius),-pi-0.86,arcAngle,false,paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false; 

 
}