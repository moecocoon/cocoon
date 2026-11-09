const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

if (!admin.apps.length) {
  admin.initializeApp();
}

const emotionKeys = [
  "😊 うれしい",
  "😌 安心",
  "🥹 がんばった",
  "😰 不安",
  "😢 悲しい",
  "😴 疲れ",
  "😡 イライラ",
  "🫂 さみしい",
];

const saveEmployeeMood = onRequest(
    {
      region: "asia-northeast1",
      maxInstances: 1,
      cors: [
        /^http:\/\/localhost:\d+$/,
        "https://cocoon-688eb.web.app",
        "https://cocoon-688eb.firebaseapp.com",
      ],
    },
    async (request, response) => {
      if (request.method !== "POST") {
        response.status(405).json({
          error: "Method not allowed",
        });
        return;
      }

      let uid;

      try {
        const authorization =
          request.headers.authorization || "";

        if (!authorization.startsWith("Bearer ")) {
          throw new Error("Missing token");
        }

        const token = authorization.slice(7).trim();
        const decoded = await admin.auth()
            .verifyIdToken(token, true);

        uid = decoded.uid;
      } catch (_) {
        response.status(401).json({
          error: "再度ログインしてください。",
        });
        return;
      }

      if (request.body?.consent !== true) {
        response.status(400).json({
          error: "集計への協力には同意が必要です。",
        });
        return;
      }

      const emotions = request.body?.emotionPercents;

      if (
        !emotions ||
        typeof emotions !== "object" ||
        Array.isArray(emotions)
      ) {
        response.status(400).json({
          error: "気分の数値が正しくありません。",
        });
        return;
      }

      const entries = Object.entries(emotions);

      if (
        entries.length < 1 ||
        entries.length > emotionKeys.length ||
        entries.some(([key, value]) =>
          !emotionKeys.includes(key) ||
          typeof value !== "number" ||
          !Number.isFinite(value) ||
          value < 0 ||
          value > 100)
      ) {
        response.status(400).json({
          error: "気分の数値が正しくありません。",
        });
        return;
      }

      // メモや氏名などは保存しない
      const emotionPercents = Object.fromEntries(entries);

      // 日付は端末から受け取らず、日本時間で決める
      const date = new Intl.DateTimeFormat("en-CA", {
        timeZone: "Asia/Tokyo",
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      }).format(new Date());

      try {
        const db = admin.firestore();
        const memberRef = db
            .collection("employeeOrganizations")
            .doc(uid);

        await db.runTransaction(async (transaction) => {
          const member = await transaction.get(memberRef);
          const membership = member.data();

          if (
            !member.exists ||
            membership.status !== "active" ||
            typeof membership.organizationId !== "string" ||
            !/^[a-zA-Z0-9_-]{1,80}$/.test(
                membership.organizationId,
            )
          ) {
            throw new Error("NOT_ACTIVE");
          }

          // 会社IDは入力値ではなく承認済み所属から取得
          const organizationId = membership.organizationId;

          const moodRef = db
              .collection("organizationMoodEntries")
              .doc(organizationId)
              .collection("days")
              .doc(date)
              .collection("entries")
              .doc(uid);

          // 同じ人の同日分は更新して、重複集計を防ぐ
          transaction.set(moodRef, {
            emotionPercents,
            consentVersion: "organization-mood-v1",
            updatedAt:
              admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        response.status(200).json({
          message: "集計用の気分を保存しました。",
        });
      } catch (error) {
        if (error.message === "NOT_ACTIVE") {
          response.status(403).json({
            error: "承認済みの所属を確認できませんでした。",
          });
          return;
        }

        logger.error("Employee mood save failed", {
          message: error.message,
        });

        response.status(500).json({
          error: "集計用の気分を保存できませんでした。",
        });
      }
    },
);

module.exports = {
  saveEmployeeMood,
};