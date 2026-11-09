const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const MIN_PARTICIPANTS = 10;

// 日本時間で、直前に完了した月曜〜日曜を取得
function getPreviousWeekDates() {
  const japanDate = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Tokyo",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());

  const today = new Date(`${japanDate}T00:00:00Z`);
  const daysSinceMonday = (today.getUTCDay() + 6) % 7;

  const start = new Date(today);
  start.setUTCDate(today.getUTCDate() - daysSinceMonday - 7);

  return Array.from({length: 7}, (_, index) => {
    const date = new Date(start);
    date.setUTCDate(start.getUTCDate() + index);
    return date.toISOString().slice(0, 10);
  });
}

// 感情を選ばなかった日は、その感情の数値を0として扱う
function emotionValue(emotions, key) {
  const value = emotions[key];

  if (value === undefined) return 0;

  if (
    typeof value !== "number" ||
    !Number.isFinite(value) ||
    value < 0 ||
    value > 100
  ) {
    throw new Error("INVALID_MOOD_VALUE");
  }

  return value;
}

async function getOrganizationMoodAggregate(organizationId) {
  if (
    typeof organizationId !== "string" ||
    !/^[a-zA-Z0-9_-]{1,80}$/.test(organizationId)
  ) {
    throw new Error("INVALID_ORGANIZATION");
  }

  const dates = getPreviousWeekDates();
  const db = admin.firestore();

  const snapshots = await Promise.all(dates.map((date) =>
    db.collection("organizationMoodEntries")
        .doc(organizationId)
        .collection("days")
        .doc(date)
        .collection("entries")
        .get(),
  ));

  const participants = new Map();

  for (const snapshot of snapshots) {
    for (const doc of snapshot.docs) {
      const data = doc.data();

      if (data.consentVersion !== "organization-mood-v1") {
        continue;
      }

      const emotions = data.emotionPercents;

      if (
        !emotions ||
        typeof emotions !== "object" ||
        Array.isArray(emotions) ||
        Object.keys(emotions).length === 0
      ) {
        throw new Error("INVALID_MOOD_DATA");
      }

      const current = participants.get(doc.id) || {
        positive: 0,
        tired: 0,
        days: 0,
      };

      // 「うれしい」と「安心」の強さの平均
      current.positive += (
        emotionValue(emotions, "😊 うれしい") +
        emotionValue(emotions, "😌 安心")
      ) / 2;

      // 「疲れ」の強さ
      current.tired += emotionValue(emotions, "😴 疲れ");
      current.days += 1;

      participants.set(doc.id, current);
    }
  }

  const base = {
    period: `${dates[0]}〜${dates[6]}`,
    minimumParticipants: MIN_PARTICIPANTS,
    isSample: false,
  };

  if (participants.size < MIN_PARTICIPANTS) {
    return {
      ...base,
      status: "insufficient_data",
      participantCount: null,
      positiveRate: null,
      tiredRate: null,
    };
  }

  let positive = 0;
  let tired = 0;

  // 記録日数が多い人に集計が偏らないよう、まず本人の週平均を計算
  for (const participant of participants.values()) {
    positive += participant.positive / participant.days;
    tired += participant.tired / participant.days;
  }

  return {
    ...base,
    status: "ready",
    participantCount: participants.size,
    positiveRate: Math.round(positive / participants.size),
    tiredRate: Math.round(tired / participants.size),
  };
}

module.exports = {
  getOrganizationMoodAggregate,
};
