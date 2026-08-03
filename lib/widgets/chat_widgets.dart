import 'package:flutter/material.dart';

import '../models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFF4ECFA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE3D6EC),
                ),
              ),
              child: Image.asset(
                'assets/images/luna.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 9),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  const Padding(
                    padding: EdgeInsets.only(
                      left: 5,
                      bottom: 5,
                    ),
                    child: Text(
                      'ルナ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8A7D96),
                      ),
                    ),
                  ),

                Container(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth * 0.74,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF8E7BBE)
                        : const Color(0xFFFFFBFF),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(25),
                      topRight: const Radius.circular(25),
                      bottomLeft: Radius.circular(
                        isUser ? 25 : 7,
                      ),
                      bottomRight: Radius.circular(
                        isUser ? 7 : 25,
                      ),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: const Color(0xFFE8DDEE),
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E7BBE).withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: isUser
                          ? Colors.white
                          : const Color(0xFF5D5264),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThinkingBubble extends StatefulWidget {
  const ThinkingBubble({super.key});

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE8DDEE),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8E7BBE).withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final dotCount = (controller.value * 3).floor() + 1;

            return Text(
              '🐶 ルナが考え中${'.' * dotCount}',
              style: const TextStyle(
                color: Color(0xFF8E7BBE),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
    );
  }
}