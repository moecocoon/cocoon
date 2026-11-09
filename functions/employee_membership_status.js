const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

// 従業員本人の所属状況を取得
const getEmployeeMembershipStatus = onRequest(
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

      try {
        const authorization =
          request.headers.authorization || "";

        if (!authorization.startsWith("Bearer ")) {
          response.status(401).json({
            error: "ログインが必要です。",
          });
          return;
        }

        const token = authorization.slice(7).trim();
        const decoded = await admin.auth()
            .verifyIdToken(token, true);

        const uid = decoded.uid;
        const db = admin.firestore();

        // 有効な所属情報を確認
        const memberDoc = await db
            .collection("employeeOrganizations")
            .doc(uid)
            .get();

        if (
          memberDoc.exists &&
          memberDoc.data().status === "active"
        ) {
          response.status(200).json({
            status: "active",
            organizationId:
              memberDoc.data().organizationId,
          });
          return;
        }

        // 承認待ちの申請を確認
        const requestDoc = await db
            .collection("employeeMembershipRequests")
            .doc(uid)
            .get();

        if (requestDoc.exists) {
          response.status(200).json({
            status: requestDoc.data().status,
            organizationId:
              requestDoc.data().organizationId,
          });
          return;
        }

        response.status(200).json({
          status: "none",
          organizationId: null,
        });
      } catch (error) {
        response.status(500).json({
          error: "所属状況を取得できませんでした。",
        });
      }
    },
);

module.exports = {
  getEmployeeMembershipStatus,
};