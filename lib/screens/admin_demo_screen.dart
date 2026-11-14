import 'package:flutter/material.dart';

class AdminDemoScreen extends StatelessWidget {
  const AdminDemoScreen({super.key});

  Widget section(String title, Widget content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF49365D),
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget emotionBar(String label, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label：$score / 100',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100,
            minHeight: 12,
            backgroundColor: const Color(0xFFEDE7F2),
            color: color,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FC),
      appBar: AppBar(
        title: const Text('企業管理画面のデモ'),
        backgroundColor: const Color(0xFFEDE2F6),
        foregroundColor: const Color(0xFF49365D),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '架空データのデモ',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF49365D),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '以下は説明用の架空データと固定の分析文です。'
            '実際の従業員情報や、今回AIが生成した結果ではありません。',
          ),
          const SizedBox(height: 24),

          section(
            'デモ会社の集計',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('会社名：サンプル株式会社（架空）'),
                const SizedBox(height: 8),
                const Text('集計期間：サンプルの1週間'),
                const SizedBox(height: 8),
                const Text('集計対象人数：30人（架空）'),
                const SizedBox(height: 24),
                emotionBar(
                  'うれしい気持ちの平均',
                  65,
                  const Color(0xFFE2AD67),
                ),
                emotionBar(
                  '疲れの平均',
                  35,
                  const Color(0xFF9B86BB),
                ),
                const Text(
                  '数値は感情の強さの平均を示す架空の値です。'
                  'その感情を持つ人の割合ではありません。',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF756B7A),
                  ),
                ),
              ],
            ),
          ),

          section(
  '1週間の気分の変化（架空データ）',
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          Text(
            '● うれしい気持ち',
            style: TextStyle(
              color: Color(0xFF9B651D),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '● 疲れ',
            style: TextStyle(
              color: Color(0xFF79609E),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const SizedBox(
        width: double.infinity,
        height: 250,
        child: CustomPaint(
          painter: DemoMoodChartPainter(),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        '感情の強さの平均（0〜100）の表示例です。\n'
        '各日の回答者は30人と仮定しています。'
        '実際の従業員の記録ではありません。\n'
        '日別データから計算した週平均は、'
        'うれしい気持ち65、疲れ35です。',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF756B7A),
          height: 1.6,
        ),
      ),
    ],
  ),
),

          section(
            '組織分析の表示例（固定サンプル）',
            const Text(
              'この架空の集計では、うれしい気持ちの平均は'
              '65、疲れの平均は35です。\n\n'
              '組織全体の平均だけでは、一人ひとりの状態や'
              '感情の原因までは分かりません。'
              'この数値だけで職場の良し悪しや、'
              '従業員の健康状態を判断することはできません。',
              style: TextStyle(fontSize: 16, height: 1.7),
            ),
          ),

          section(
            '職場改善アクションの表示例',
            const Text(
              '1．負担を感じる業務がないか、任意で意見を聞く\n\n'
              '2．休憩を取りやすい運用になっているか確認する\n\n'
              '3．次の期間の集計と合わせて、変化を確認する\n\n'
              'これらは一般的な検討例です。'
              '集計から原因を断定した提案ではありません。',
              style: TextStyle(fontSize: 16, height: 1.7),
            ),
          ),

          const Text(
            'このデモ画面ではAPI呼び出し・分析回数の消費・'
            '分析履歴への保存は行いません。\n'
            '実際の管理画面では、人数条件を満たした集計のみを'
            '表示・分析します。',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF756B7A),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class DemoMoodChartPainter extends CustomPainter {
  const DemoMoodChartPainter();

  static const happyValues = <double>[
    58, 63, 60, 70, 65, 72, 67,
  ];

  static const tiredValues = <double>[
    42, 37, 40, 30, 35, 28, 33,
  ];

  static const days = [
    '月', '火', '水', '木', '金', '土', '日',
  ];

  void drawLabel(
    Canvas canvas,
    String text,
    Offset position, {
    Color color = const Color(0xFF756B7A),
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, position);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0;
    const top = 12.0;
    const right = 16.0;
    const bottom = 32.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5DDEB)
      ..strokeWidth = 1;

    // 横線と縦軸の数値
    for (var value = 0; value <= 100; value += 25) {
      final y = top + chartHeight * (1 - value / 100);

      canvas.drawLine(
        Offset(left, y),
        Offset(left + chartWidth, y),
        gridPaint,
      );

      drawLabel(
        canvas,
        '$value',
        Offset(2, y - 7),
      );
    }

    // 曜日
    for (var i = 0; i < days.length; i++) {
      final x = left + chartWidth * i / 6;

      drawLabel(
        canvas,
        days[i],
        Offset(x - 6, top + chartHeight + 10),
      );
    }

    void drawSeries(List<double> values, Color color) {
      final path = Path();
      final points = <Offset>[];

      for (var i = 0; i < values.length; i++) {
        final point = Offset(
          left + chartWidth * i / 6,
          top + chartHeight * (1 - values[i] / 100),
        );

        points.add(point);

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, linePaint);

      final pointPaint = Paint()..color = color;

      for (final point in points) {
        canvas.drawCircle(point, 4, pointPaint);
      }
    }

    drawSeries(
      happyValues,
      const Color(0xFF9B651D),
    );

    drawSeries(
      tiredValues,
      const Color(0xFF79609E),
    );
  }

  @override
  bool shouldRepaint(
    covariant DemoMoodChartPainter oldDelegate,
  ) {
    return false;
  }
}