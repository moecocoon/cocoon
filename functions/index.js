const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const OpenAI = require("openai");

// Firebase Secret Manager に保存したAPIキー
const openaiApiKey = defineSecret("OPENAI_API_KEY");

exports.lunaChat = onRequest(
    {
      secrets: [openaiApiKey],

      // 開発中の予期しない大量実行を抑える
      maxInstances: 2,

      // COCOONの主な利用地域に近い場所
      region: "asia-northeast1",

      cors: true,
    },
    async (request, response) => {
      // POST以外は受け付けない
      if (request.method !== "POST") {
        response.status(405).json({
          error: "Method not allowed",
        });
        return;
      }

      try {
        const userText =
          typeof request.body?.message === "string" ?
            request.body.message.trim() :
            "";

        // 空のメッセージは送らない
        if (!userText) {
          response.status(400).json({
            error: "メッセージがありません。",
          });
          return;
        }

        // 極端に長い入力によるAPI使用量増加を防ぐ
        if (userText.length > 2000) {
          response.status(400).json({
            error: "メッセージが長すぎます。",
          });
          return;
        }

        const openai = new OpenAI({
          apiKey: openaiApiKey.value(),
        });

        const result = await openai.responses.create({
  model: "gpt-5-mini",

  reasoning: {
    effort: "low",
  },

  instructions: `
あなたはメンタルケアアプリ「COCOON」に登場する
白い犬のキャラクター「ルナ」です。

ユーザーが安心して気持ちを話せる、
自然で穏やかな会話相手として返答してください。

【会話の基本】
・日本語で自然に話す
・基本は短めの返答にする
・相手が使った言葉をそのまま繰り返しすぎない
・毎回質問で終わらせない
・質問するときは一度に1つまで
・説教や決めつけをしない
・無理に前向きにさせない
・ユーザーの感情を勝手に断定しない
・「〜なんだね」を連発しない
・テンプレートのような返答を避ける
・絵文字は必要な場合だけ少量使う

【ルナの雰囲気】
やさしく、親しみやすく、落ち着いている。
幼すぎる話し方や過剰にかわいい話し方にはしない。
ユーザーの話をちゃんと聞いてから返す。

【大切なこと】
医師や専門家の代わりをしない。
診断をしない。
危険が差し迫っている可能性がある場合は、
通常の雑談より安全を優先する。
  `.trim(),

  input: userText,

  max_output_tokens: 800,
});

        const reply = result.output_text?.trim();

        if (!reply) {
          throw new Error("OpenAI returned an empty response.");
        }

        response.status(200).json({
          reply: reply,
        });
      } catch (error) {
        logger.error("lunaChat error", error);

        response.status(500).json({
          error: "ルナの返事を作れませんでした。",
        });
      }
    },
);