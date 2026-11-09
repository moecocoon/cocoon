
const admin = require("firebase-admin");
const readline = require("node:readline/promises");
const {stdin: input, stdout: output} = require("node:process");

async function main() {
  const uid = process.argv[2];

  if (!uid) {
    throw new Error("UIDを指定してください。");
  }

  admin.initializeApp({
    projectId: "cocoon-688eb",
  });

  const user = await admin.auth().getUser(uid);

  console.log("対象ユーザー:", user.email || uid);

  const rl = readline.createInterface({input, output});
  let answer;

  try {
    answer = await rl.question(
        "このユーザーに管理者権限を付けますか？ (yes/no): ",
    );
  } finally {
    rl.close();
  }

  if (answer !== "yes") {
    console.log("キャンセルしました。");
    return;
  }

  await admin.auth().setCustomUserClaims(uid, {
    ...user.customClaims,
    admin: true,
  });

  console.log("管理者権限を設定しました。");
}

main().catch((error) => {
  console.error("エラー:", error.message);
  process.exitCode = 1;
});

