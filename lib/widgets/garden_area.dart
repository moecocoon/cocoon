import 'package:flutter/material.dart';

import 'luna_widget.dart';

class GardenArea extends StatelessWidget {
  final Widget? luna;

  const GardenArea({
    super.key,
    this.luna,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: const DecorationImage(
          image: AssetImage(
            'assets/images/garden/garden_bg.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              left: 25,
              top: 70,
              child: Image.asset(
                'assets/images/emotion_anxiety.png',
                width: 55,
              ),
            ),

            Positioned(
              right: 25,
              top: 95,
              child: Image.asset(
                'assets/images/emotion_peace.png',
                width: 55,
              ),
            ),

            Positioned(
              left: 35,
              bottom: 65,
              child: Image.asset(
                'assets/images/emotion_lonely.png',
                width: 58,
              ),
            ),

            Positioned(
              right: 30,
              bottom: 60,
              child: Image.asset(
                'assets/images/emotion_tired.png',
                width: 58,
              ),
            ),

            Positioned(
              right: 105,
              top: 190,
              child: Image.asset(
                'assets/images/emotion_angry.png',
                width: 55,
              ),
            ),

            Align(
              alignment: const Alignment(0, 0.58),
              child: luna ??
                  const LunaWidget(
                    size: 170,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}