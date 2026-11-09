
const admin = require("firebase-admin");


if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const DAILY_LIMIT = 3;

// 日本時間の日付を取得

function getJapanDate() {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "Asia/Tokyo",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());

  const values = Object.fromEntries(
      parts.map((part) => [part.type, part.value]),
  );

  return `${values.year}-${values.month}-${values.day}`;
}


// 管理者ごとの1日の利用回数を確認
async function checkAndUseAnalysisLimit(uid) {
  const today = getJapanDate();

  const docRef = db
      .collection("organizationAnalysisUsage")
      .doc(`${uid}_${today}`);

  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(docRef);

    const currentCount = snapshot.exists ?
      snapshot.data().count || 0 : 0;

    if (currentCount >= DAILY_LIMIT) {
      return {
        allowed: false,
        remaining: 0,
      };
    }

    transaction.set(docRef, {
      count: currentCount + 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    return {
      allowed: true,
      remaining: DAILY_LIMIT - currentCount - 1,
    };
  });
}

// 今日のAI分析の残り回数を取得する
async function getRemainingAnalysisCount(uid) {
  const today = getJapanDate();

  const docRef = db
      .collection("organizationAnalysisUsage")
      .doc(`${uid}_${today}`);

  const snapshot = await docRef.get();

  const currentCount = snapshot.exists ?
    snapshot.data().count || 0 : 0;

  return Math.max(0, DAILY_LIMIT - currentCount);
}

module.exports = {
  checkAndUseAnalysisLimit,
  getRemainingAnalysisCount,
};
