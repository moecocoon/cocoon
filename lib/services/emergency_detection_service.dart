enum EmergencyLevel {
  none,
  possible,
  urgent,
}

class EmergencyDetectionService {
  static EmergencyLevel detect(String message) {
    final text = message.trim();

    if (text.isEmpty) {
      return EmergencyLevel.none;
    }

    // 直接的な緊急支援の要請
    final urgentPhrases = [
      '今すぐ助けて',
      '救急車を呼んで',
      '警察を呼んで',
      '意識がなくなりそう',
      '息ができない',
    ];

    if (urgentPhrases.any(text.contains)) {
      return EmergencyLevel.urgent;
    }

    // 支援が必要かもしれない状況
    final possiblePhrases = [
      '誰かに助けてほしい',
      '一人では対処できない',
      '誰かに連絡したい',
      '一緒にいてほしい',
      '助けを求めたい',
    ];

    if (possiblePhrases.any(text.contains)) {
      return EmergencyLevel.possible;
    }

    return EmergencyLevel.none;
  }
}