import 'package:flutter/material.dart';

class StressRing extends StatelessWidget {
  final double stressScore; //από 0-10

  const StressRing ({Key? key, required this.stressScore}) : super(key: key);
  Map <String,Color>_colorsStressScore(double stressScore)
  {
    if (stressScore<= 4){
      return{
        'ring': const Color.fromARGB(255, 96, 164, 2), 
        'text': const Color.fromARGB(255, 39, 80, 10),
      };
    } else if (stressScore <= 7){
      return{
        'ring': const Color.fromARGB(255, 222, 192, 0), 
        'text': const Color.fromARGB(255, 39, 80, 10),
      };
    }  
    else {
      return{
        'ring': const Color.fromARGB(255, 208, 114, 6), 
        'text': const Color.fromARGB(255, 39, 80, 10),
      }; 
    }
  }
  @override
  Widget build(BuildContext context) {
    final colors = _colorsStressScore(stressScore);
    return SizedBox(
      width: 270,
      height: 270,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 270,
            height: 270,
            child: CustomPaint(
              painter: _StressRingPainter(color: colors['ring']!),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stressScore.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: colors['text'],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Επίπεδο Άγχους',
                style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 25, 96, 25)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _StressRingPainter extends CustomPainter {
  final Color color;

  _StressRingPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final radius = (size.width - 20) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, paint);
  }
  @override
  bool shouldRepaint(_StressRingPainter oldDelegate) => oldDelegate.color != color;
}