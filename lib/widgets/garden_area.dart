import 'package:flutter/material.dart';

import 'luna_widget.dart';

class GardenArea extends StatelessWidget {
  final Widget? luna;
  final Function(String)? onEmotionTap;

  const GardenArea({
    super.key,
    this.luna,
    this.onEmotionTap,
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
  child: GestureDetector(
    onTap: () => onEmotionTap?.call("anxiety"),
    child: Image.asset(
      'assets/images/emotion_anxiety.png',
      width: 55,
    ),
  ),
),

            Positioned(
              right: 25,
              top: 95,
              child: GestureDetector(
                onTap: () => onEmotionTap?.call("peace"),
                child: Image.asset(
                'assets/images/emotion_peace.png',
                width: 55,
              ),
            ),
            ),
            
Positioned(
  left: 35,
  bottom: 65,
  child: GestureDetector(
    onTap: () => onEmotionTap?.call("lonely"),
    child: Image.asset(
      'assets/images/emotion_lonely.png',
      width: 58,
    ),
  ),
),


            Positioned(
              right: 30,
              bottom: 60,
              child: GestureDetector(
                onTap: () => onEmotionTap?.call("tired"),
                child: Image.asset(
                  'assets/images/emotion_tired.png',
                  width: 58,
                ),
              ),
            ),

            Positioned(
              right: 105,
              top: 190,
              child: GestureDetector(
                onTap: () => onEmotionTap?.call("angry"),
                child: Image.asset(
                  'assets/images/emotion_angry.png',
                  width: 55,
                ),
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