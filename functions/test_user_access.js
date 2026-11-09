const readline = require("node:readline/promises");
const {stdin: input, stdout: output} = require("node:process");

async function main() {
  const rl = readline.createInterface({input, output});

  try {
    const email = await rl.question("テスト用メールアドレス: ");
    const password = await rl.question("テスト用パスワード: ");

    const apiKey = await rl.question("Firebase Web APIキー: ");

    const signInResponse = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`,
        {
          method: "POST",
          headers: {"Content-Type": "application/json"},
          body: JSON.stringify({
            email,
            password,
            returnSecureToken: true,
          }),
        },
    );

    const signInData = await signInResponse.json();

    if (!signInResponse.ok) {
      console.log("ログイン失敗:", signInData.error?.message);
      return;
    }

    const response = await fetch(
        "https://asia-northeast1-cocoon-688eb.cloudfunctions.net/getOrganizationAnalysisHistory",
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${signInData.idToken}`,
          },
        },
    );

    console.log("APIステータス:", response.status);

    if (response.status === 403) {
      console.log("成功：一般利用者のアクセスが拒否されました。");
    } else {
      console.log("要確認：想定外のステータスです。");
    }
  } finally {
    rl.close();
  }
}

main().catch((error) => {
  console.error("テストエラー:", error.message);
  process.exitCode = 1;
});