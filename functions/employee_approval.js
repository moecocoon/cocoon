const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

if (!admin.apps.length) {
  admin.initializeApp();
}

// 管理者が所属する会社IDを取得
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

  if (decodedToken.admin !== true) {
    throw new Error("管理者権限がありません。");
  }

  const adminDoc = await admin.firestore()
      .collection("organizationAdmins")
      .doc(decodedToken.uid)
      .get();

  if (!adminDoc.exists) {
    throw new Error("所属会社が登録されていません。");
  }

  const organizationId = adminDoc.data()?.organizationId;

  if (typeof organizationId !== "string" ||
      !organizationId.trim()) {
    throw new Error("会社IDが正しくありません。");
  }

  return organizationId;
}

// 管理者向け：所属申請一覧を取得
const getEmployeeMembershipRequests = onRequest(
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
      if (request.method !== "GET") {
        response.status(405).json({
          error: "Method not allowed",
        });
        return;
      }

      let organizationId;

      try {
        organizationId = await getAdminOrganizationId(request);
      } catch (error) {
        response.status(403).json({
          error: "管理者権限を確認できませんでした。",
        });
        return;
      }

      try {
        // 自分の会社への承認待ち申請だけを取得
        const snapshot = await admin.firestore()
            .collection("employeeMembershipRequests")
            .where("organizationId", "==", organizationId)
            .where("status", "==", "pending")
            .limit(50)
            .get();

       const requests = snapshot.docs.map((doc) => {
  const data = doc.data();

  return {
    id: doc.id,
    employeeName: data.employeeName || "氏名未登録",
    status: data.status,
    createdAt:
      data.createdAt?.toDate().toISOString() ?? null,
  };
});

        response.status(200).json({requests});
      } catch (error) {
        logger.error("Membership requests lookup failed", {
          message: error.message,
        });

        response.status(500).json({
          error: "所属申請一覧を取得できませんでした。",
        });
      }
    },
);

// 管理者向け：従業員の所属申請を承認
const approveEmployeeMembership = onRequest(
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

      let organizationId;

      try {
        organizationId = await getAdminOrganizationId(request);
      } catch (error) {
        response.status(403).json({
          error: "管理者権限を確認できませんでした。",
        });
        return;
      }

      const requestId = request.body?.requestId;

      if (
        typeof requestId !== "string" ||
        !/^[a-zA-Z0-9_-]{1,128}$/.test(requestId)
      ) {
        response.status(400).json({
          error: "申請IDが正しくありません。",
        });
        return;
      }

      try {
        const db = admin.firestore();

        const requestRef = db
            .collection("employeeMembershipRequests")
            .doc(requestId);

        await db.runTransaction(async (transaction) => {
          const requestDoc = await transaction.get(requestRef);

          if (!requestDoc.exists) {
            throw new Error("REQUEST_NOT_FOUND");
          }

          const data = requestDoc.data();

          // 申請IDと従業員UIDの一致を確認
if (data.uid !== requestId) {
  throw new Error("INVALID_REQUEST");
}

          // 別会社の申請は承認できない
          if (data.organizationId !== organizationId) {
            throw new Error("FORBIDDEN");
          }

          if (data.status !== "pending") {
            throw new Error("NOT_PENDING");
          }

          // 従業員の所属情報
          const memberRef = db
              .collection("employeeOrganizations")
              .doc(requestId);

// 既存の所属情報を確認
const existingMember = await transaction.get(memberRef);

// すでに所属情報がある場合は承認しない
if (existingMember.exists) {
  throw new Error("ALREADY_MEMBER");
}

          transaction.set(memberRef, {
            organizationId,
            status: "active",
            approvedAt:
              admin.firestore.FieldValue.serverTimestamp(),
          });

          transaction.update(requestRef, {
            status: "approved",
            approvedAt:
              admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        response.status(200).json({
          message: "所属申請を承認しました。",
        });
      } catch (error) {
        logger.error("Membership approval failed", {
          message: error.message,
        });

        if (error.message === "REQUEST_NOT_FOUND") {
          response.status(404).json({
            error: "申請が見つかりません。",
          });
        } else if (error.message === "FORBIDDEN") {
          response.status(403).json({
            error: "別会社の申請は承認できません。",
          });
        } 
        else if (error.message === "INVALID_REQUEST") {
  response.status(400).json({
    error: "申請データが正しくありません。",
  });
}
        else if (error.message === "NOT_PENDING") {
          response.status(409).json({
            error: "承認待ちの申請ではありません。",
          });
        } 
        else if (error.message === "ALREADY_MEMBER") {
  response.status(409).json({
    error: "この従業員はすでに会社に所属しています。",
  });
} else {
          response.status(500).json({
            error: "所属申請を承認できませんでした。",
          });
        }
      }
    },
);

module.exports = {
  getEmployeeMembershipRequests,
  approveEmployeeMembership,
};
