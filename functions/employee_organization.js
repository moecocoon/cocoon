const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

if (!admin.apps.length) {
  admin.initializeApp();
}

// 従業員が会社への所属を申請するAPI
const requestOrganizationMembership = onRequest(
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

      // 本人確認
      let uid;

      try {
        const authorization =
          request.headers.authorization || "";

        if (!authorization.startsWith("Bearer ")) {
          throw new Error("認証情報がありません。");
        }

        const idToken = authorization.slice(7).trim();

        const decodedToken =
          await admin.auth().verifyIdToken(idToken, true);

        uid = decodedToken.uid;
      } catch (error) {
        response.status(401).json({
          error: "ログインが必要です。",
        });
        return;
      }

      // 所属を希望する会社ID
      const organizationId = request.body?.organizationId;

      // 申請者の氏名を確認
const employeeName = request.body?.employeeName;

if (
  typeof employeeName !== "string" ||
  employeeName.trim().length < 1 ||
  employeeName.trim().length > 50
) {
  response.status(400).json({
    error: "氏名を1〜50文字で入力してください。",
  });
  return;
}



      if (
        typeof organizationId !== "string" ||
        !/^[a-zA-Z0-9_-]{1,80}$/.test(organizationId)
      ) {
        response.status(400).json({
          error: "会社IDが正しくありません。",
        });
        return;
      }

      try {
        // 会社の存在確認
        const organizationDoc = await admin.firestore()
            .collection("organizations")
            .doc(organizationId)
            .get();

        if (!organizationDoc.exists) {
          response.status(404).json({
            error: "会社が見つかりません。",
          });
          return;
        }

        // すでに所属申請がある場合は、再申請を受け付けない
const existingRequest = await admin.firestore()
    .collection("employeeMembershipRequests")
    .doc(uid)
    .get();

if (existingRequest.exists) {
  response.status(409).json({
    error: "すでに所属申請が登録されています。",
  });
  return;
}

  // 所属申請を保存（承認待ち）
await admin.firestore()
    .collection("employeeMembershipRequests")
    .doc(uid)
    .create({
      uid: uid,
      organizationId: organizationId,
      employeeName: employeeName.trim(),
      status: "pending",
      createdAt:
        admin.firestore.FieldValue.serverTimestamp(),
    });



        response.status(200).json({
          message: "所属申請を受け付けました。",
          status: "pending",
        });
      } catch (error) {
if (error.code === 6 || error.code === "already-exists") {
  response.status(409).json({
    error: "すでに所属申請が登録されています。",
  });
  return;
}

        logger.error("Membership request failed", {
          message: error.message,
        });

        response.status(500).json({
          error: "所属申請を保存できませんでした。",
        });
      }
    },
);

module.exports = {
  requestOrganizationMembership,
};