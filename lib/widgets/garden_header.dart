import 'dart:ui';

import 'package:flutter/material.dart';

class GardenHeader extends StatelessWidget {
  final String weatherText;
  final String cityName;
  final String lunaMessage;

  const GardenHeader({
    super.key,
    required this.weatherText,
    required this.cityName,
    required this.lunaMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.64),
                const Color(0xFFF6EEFA).withOpacity(0.48),
                const Color(0xFFEDE3F4).withOpacity(0.40),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.82),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF72598E).withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -12,
                right: -8,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 62,
                  color: Colors.white.withOpacity(0.24),
                ),
              ),

              Positioned(
                bottom: -18,
                left: -6,
                child: Icon(
                  Icons.local_florist_outlined,
                  size: 76,
                  color: const Color(0xFF89A77B).withOpacity(0.12),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.42),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.66),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🌿',
                              style: TextStyle(fontSize: 15),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'ルナからのおたより',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF745E88),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.40),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.66),
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: Color(0xFFD58FB0),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 94,
                        height: 94,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.36),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.84),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF72598E)
                                  .withOpacity(0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/luna.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'おかえり。',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF55475F),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              lunaMessage,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF675A70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.34),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.62),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _infoItem(
                            icon: Icons.location_on_outlined,
                            text: cityName,
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withOpacity(0.72),
                        ),

                        Expanded(
                          child: _infoItem(
                            icon: Icons.wb_sunny_outlined,
                            text: weatherText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF806995),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF62556B),
            ),
          ),
        ),
      ],
    );
  }
}