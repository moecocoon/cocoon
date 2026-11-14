const {
  getOrganizationMoodAggregate,
} = require("./organization_mood_aggregate");
const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const {defineSecret} = require("firebase-functions/params");
const OpenAI = require("openai");
const {
  checkAndUseAnalysisLimit,
  getRemainingAnalysisCount,
} = require("./analysis_rate_limit");

const openaiApiKey = defineSecret("OPENAI_API_KEY");

if (!admin.apps.length) {
  admin.initializeApp();
}

// ログイン中の管理者が所属する会社IDを取得
async function getAdminOrganizationId(request) {
  const authorization = request.headers.authorization || "";

  if (!authorization.startsWith("Bearer ")) {
    throw new Error("認証情報がありません。");
  }

  const idToken = authorization.slice(7).trim();

  const decodedToken = await admin.auth().verifyIdToken(
      idToken,
      true,
  );

  // 管理者権限を確認
  if (decodedToken.admin !== true) {
    throw new Error("管理者権限がありません。");
  }

  // Firestoreから管理者の会社情報を取得
  const adminDoc = await admin.firestore()
      .collection("organizationAdmins")
      .doc(decodedToken.uid)
      .get();

  if (!adminDoc.exists) {
    throw new Error("管理者の会社情報が登録されていません。");
  }

  const organizationId = adminDoc.data()?.organizationId;

  if (typeof organizationId !== "string" ||
      !organizationId.trim()) {
    throw new Error("会社IDが正しく登録されていません。");
  }

  return organizationId;
}

// 管理者権限を確認するための関数
async function verifyAdmin(request) {

  
  const authorization = request.headers.authorization || "";

  if (!authorization.startsWith("Bearer ")) {
    return false;
  }

  const idToken = authorization.slice(7).trim();

  if (!idToken) {
    return false;
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(
        idToken,
        true,
    );

    return decodedToken.admin === true;
  } catch (error) {
    logger.warn("Admin authentication failed", {
      code: error.code,
    });
    return false;
  }
}


/**
 * AI分析の動作確認に使う架空の集計データ。
 * 実際の従業員情報は含まれていません。
 */
const sampleOrganizationData = {
  period: "直近7日間",
  participantCount: 30,
  dailyRates: [
    {day: "月", positive: 58, tired: 42},
    {day: "火", positive: 63, tired: 37},
    {day: "水", positive: 60, tired: 40},
    {day: "木", positive: 70, tired: 30},
    {day: "金", positive: 65, tired: 35},
    {day: "土", positive: 72, tired: 28},
    {day: "日", positive: 68, tired: 32},
  ],
};


async function generateOrganizationAnalysis(data) {
  const openai = new OpenAI({
    apiKey: openaiApiKey.value(),
  });

  const result = await openai.responses.create({
    model: "gpt-5-mini",
    reasoning: {
      effort: "low",
    },
    instructions: `
あなたは企業の職場環境改善を支援するAIです。

渡された組織全体の集計データだけを分析し、
日本語で分かりやすく回答してください。

【分析ルール】
・個人の心理状態や病気を推測しない
・気分の変化から原因を断定しない
・従業員の監視や評価につながる提案をしない
・データにない情報を作らない
・小規模集計や個人情報は扱わない
・positiveRateは「うれしい・安心」の強さの平均、tiredRateは「疲れ」の強さの平均（0〜100）であり、人数の割合ではない
・週全体の平均から、日別の変化や週前半・後半の傾向を推測しない
・改善案は実行しやすいものを3つ提案する

次の形式で回答してください。

【組織分析】
分析文

【改善アクション】
① 提案
② 提案
③ 提案
    `.trim(),
    input: JSON.stringify(data),
    max_output_tokens: 1400,
  });

  const reply = result.output_text?.trim();

  if (!reply) {
    throw new Error("AI analysis returned an empty response.");
  }

  return reply;
}


const organizationAnalysis = onRequest(
    {
      region: "asia-northeast1",
      secrets: [openaiApiKey],
      maxInstances: 1,
      timeoutSeconds: 60,
cors: [
  "http://localhost:3000",
  "http://localhost:5000",
  /^http:\/\/localhost:\d+$/,
  "https://cocoon-688eb.web.app",
  "https://cocoon-688eb.firebaseapp.com",
],
    },
    async (request, response) => {
      // POST以外は拒否
      if (request.method !== "POST") {
        response.status(405).json({
          error: "Method not allowed",
        });
        return;
      }

      // Firebaseの管理者権限をサーバー側で確認
      const isAdmin = await verifyAdmin(request);

      if (!isAdmin) {
        response.status(403).json({
          error: "管理者権限がありません。",
        });
        return;
      }


// 管理者が所属する会社を確認
let organizationId;
let aggregateData;

try {
  organizationId = await getAdminOrganizationId(request);

  // 登録されている会社が実在するか確認
  const organizationDoc = await admin.firestore()
      .collection("organizations")
      .doc(organizationId)
      .get();

  if (!organizationDoc.exists) {
    response.status(403).json({
      error: "所属する会社が登録されていません。",
    });
    return;
  }

aggregateData =
  await getOrganizationMoodAggregate(organizationId);

if (aggregateData.status !== "ready") {
  response.status(403).json({
    error: "回答人数が不足しているため、集計とAI分析を表示できません。",
  });
  return;
}

} catch (error) {
  logger.warn("Organization authorization failed", {
    message: error.message,
  });

  response.status(403).json({
    error: "会社情報を確認できませんでした。",
  });
  return;
}

     // 管理者の利用回数を確認
let remaining = 0;

try {
        const authorization =
          request.headers.authorization || "";

        const idToken = authorization.slice(7).trim();

        const decodedToken = await admin.auth().verifyIdToken(
            idToken,
            true,
        );

        const limitResult = await checkAndUseAnalysisLimit(
            decodedToken.uid,
        );

        remaining = limitResult.remaining;

        if (!limitResult.allowed) {
          response.status(429).json({
            error: "AI組織分析は1日3回まで利用できます。",
            remaining: 0,
          });
          return;
        }
      } catch (error) {
        logger.error("Analysis rate limit check failed", {
          message: error.message,
        });

        response.status(503).json({
          error: "利用回数を確認できませんでした。",
        });
        return;
      }


      try {
        // 人数条件を満たした所属会社の集計データを使用
       const analysis = await generateOrganizationAnalysis(
    aggregateData,
);

// AI分析結果を会社ごとのFirestoreに保存
await admin.firestore()
    .collection("organizations")
    .doc(organizationId)
    .collection("analysisHistory")
    .add({
      analysis: analysis,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      participantCount: aggregateData.participantCount,
      positiveRate: aggregateData.positiveRate,
      tiredRate: aggregateData.tiredRate,
      isSample: false,
    });

        response.status(200).json({
  analysis,
  isSample: false,
  remaining,
});
      } catch (error) {
        logger.error("Organization analysis failed", {
          message: error.message,
        });

        response.status(500).json({
          error: "組織分析を生成できませんでした。",
        });
      }
    },
);

// AI分析の残り回数を取得するAPI
const getAnalysisRemaining = onRequest(
  {
    region: "asia-northeast1",
    cors: [
      /^http:\/\/localhost:\d+$/,
      "https://cocoon-688eb.web.app",
      "https://cocoon-688eb.firebaseapp.com",
    ],
    maxInstances: 1,
  },
  async (request, response) => {
    if (request.method !== "GET") {
      response.status(405).json({
        error: "Method not allowed",
      });
      return;
    }

    // 管理者権限を確認
    const isAdmin = await verifyAdmin(request);

    if (!isAdmin) {
      response.status(403).json({
        error: "管理者権限がありません。",
      });
      return;
    }

    try {
      const authorization =
        request.headers.authorization || "";

      const idToken = authorization.slice(7).trim();

      const decodedToken = await admin.auth().verifyIdToken(
          idToken,
          true,
      );

      const remaining = await getRemainingAnalysisCount(
          decodedToken.uid,
      );

      response.status(200).json({
        remaining,
      });
    } catch (error) {
      logger.error("Remaining count check failed", {
        message: error.message,
      });

      response.status(503).json({
        error: "残り利用回数を取得できませんでした。",
      });
    }
  },
);
// 管理者の所属会社を確認するAPI
const getMyOrganization = onRequest(
    {
      region: "asia-northeast1",
      cors: [
        /^http:\/\/localhost:\d+$/,
        "https://cocoon-688eb.web.app",
        "https://cocoon-688eb.firebaseapp.com",
      ],
      maxInstances: 1,
    },
    async (request, response) => {
      response.set("Cache-Control", "no-store");

      if (request.method !== "GET") {
        response.status(405).json({
          error: "Method not allowed",
        });
        return;
      }

      let organizationId;

      try {
        organizationId =
          await getAdminOrganizationId(request);
      } catch (_) {
        response.status(403).json({
          error: "管理者権限を確認できませんでした。",
        });
        return;
      }

      try {
        const organizationDoc = await admin.firestore()
            .collection("organizations")
            .doc(organizationId)
            .get();

        if (!organizationDoc.exists) {
          response.status(403).json({
            error: "所属する会社が見つかりません。",
          });
          return;
        }

        const aggregate =
          await getOrganizationMoodAggregate(organizationId);

        response.status(200).json({
          organizationId,
          organizationName: organizationDoc.data().name || "",
          aggregate,
        });
      } catch (error) {
        logger.error("Organization aggregate lookup failed", {
          message: error.message,
        });

        response.status(500).json({
          error: "会社の集計データを取得できませんでした。",
        });
      }
    },
);

// 会社別のAI分析履歴を取得するAPI
const getOrganizationAnalysisHistory = onRequest(
  {
    region: "asia-northeast1",
    cors: [
      /^http:\/\/localhost:\d+$/,
      "https://cocoon-688eb.web.app",
      "https://cocoon-688eb.firebaseapp.com",
    ],
    maxInstances: 1,
  },
  async (request, response) => {
    if (request.method !== "GET") {
      response.status(405).json({
        error: "Method not allowed",
      });
      return;
    }

    let organizationId;

    try {
      // 管理者の認証と所属会社の確認
      organizationId = await getAdminOrganizationId(request);
    } catch (error) {
      response.status(403).json({
        error: "管理者権限を確認できませんでした。",
      });
      return;
    }

    try {
      // 所属会社の最新20件を取得
      const snapshot = await admin.firestore()
          .collection("organizations")
          .doc(organizationId)
          .collection("analysisHistory")
          .orderBy("createdAt", "desc")
          .limit(20)
          .get();

      const history = snapshot.docs.map((doc) => {
        const data = doc.data();

        return {
          id: doc.id,
          analysis: data.analysis,
          createdAt: data.createdAt?.toDate().toISOString() ?? null,
          participantCount: data.participantCount,
          positiveRate: data.positiveRate,
          tiredRate: data.tiredRate,
          isSample: data.isSample,
        };
      });

      response.status(200).json({history});
    } catch (error) {
      logger.error("Analysis history lookup failed", {
        message: error.message,
      });

      response.status(500).json({
        error: "分析履歴を取得できませんでした。",
      });
    }
  },
);

module.exports = {
  organizationAnalysis,
  getAnalysisRemaining,
  getMyOrganization,
  getOrganizationAnalysisHistory,
};


