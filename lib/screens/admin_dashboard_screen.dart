import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {

      // AI分析を実行中かどうか
bool isAnalyzing = false;

// AIが生成した分析結果
String? aiAnalysis;

// Firestoreから取得したAI分析履歴
List<Map<String, dynamic>> analysisHistory = [];

// 従業員から届いた所属申請一覧
List<Map<String, dynamic>> membershipRequests = [];

// 所属申請一覧を読み込み中かどうか
bool isLoadingMembershipRequests = false;

// 所属申請一覧の取得エラー
String? membershipRequestsError;

// エラーメッセージ
String? analysisError;

// AI分析の残り利用回数
int? remainingAnalyses;

String? organizationId;
String? organizationName;

int? participantCount;
int? positiveRate;
int? tiredRate;

String? aggregateStatus;
String? aggregatePeriod;

// 管理者と会社ごとにAI分析の保存先を分ける
String? get analysisStorageKey {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final companyId = organizationId;

  if (userId == null || companyId == null) {
    return null;
  }

  return 'cocoon_ai_analysis_${userId}_$companyId';
}

// 保存したAI分析結果を読み込む
Future<void> loadSavedAnalysis() async {
  final storageKey = analysisStorageKey;

  if (storageKey == null) return;

  final prefs = await SharedPreferences.getInstance();
  final savedAnalysis = prefs.getString(storageKey);

  if (!mounted || storageKey != analysisStorageKey) return;

  setState(() {
    aiAnalysis = savedAnalysis;
  });
}

Future<void> approveMembership(String requestId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('ログインが必要です。');
    }

    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse(
        'https://asia-northeast1-cocoon-688eb.cloudfunctions.net/approveEmployeeMembership',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'requestId': requestId,
      }),
    ).timeout(const Duration(seconds: 20));

    final data = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.statusCode == 200
              ? '所属申請を承認しました。'
              : (data['error']?.toString() ?? '承認に失敗しました。'),
        ),
      ),
    );

    if (response.statusCode == 200) {
      await loadMembershipRequests();
    }
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('通信エラーが発生しました。'),
      ),
    );
  }
}

@override
void initState() {
  super.initState();
  loadRemainingAnalyses();
  loadOrganization();
  loadAnalysisHistory();
  loadMembershipRequests();
}

Future<void> loadOrganization() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

debugPrint('会社情報確認：ユーザー=${user == null ? "未ログイン" : "ログイン済み"}');

if (user == null) {
  return;
}

    final token = await user.getIdToken();

    final response = await http.get(
      Uri.parse(
        'https://asia-northeast1-cocoon-688eb.cloudfunctions.net/getMyOrganization',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
  organizationId = data['organizationId'];
  organizationName = data['organizationName'];

  final aggregate = data['aggregate'];


aggregateStatus = aggregate['status'] as String?;
aggregatePeriod = aggregate['period'] as String?;

  participantCount = aggregate['participantCount'] as int?;
  positiveRate = aggregate['positiveRate'] as int?;
  tiredRate = aggregate['tiredRate'] as int?;
});

// 以前のサンプル分析を自動表示しない

} else {
      debugPrint('会社情報取得エラー: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('会社情報取得エラー: $e');
  }
}

// 従業員の所属申請一覧を取得
Future<void> loadMembershipRequests() async {
  if (isLoadingMembershipRequests) return;

  setState(() {
    isLoadingMembershipRequests = true;
    membershipRequestsError = null;
  });

  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('ログインが必要です。');
    }

    final token = await user.getIdToken();

    final response = await http.get(
      Uri.parse(
        'https://asia-northeast1-cocoon-688eb.cloudfunctions.net/getEmployeeMembershipRequests',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('申請一覧を取得できませんでした。');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (!mounted) return;

    setState(() {
      membershipRequests =
          List<Map<String, dynamic>>.from(data['requests']);
    });
  } catch (error) {
    if (!mounted) return;

    setState(() {
      membershipRequestsError = error.toString().replaceFirst(
        'Exception: ',
        '',
      );
    });
  } finally {
    if (mounted) {
      setState(() {
        isLoadingMembershipRequests = false;
      });
    }
  }
}

// 会社別のAI分析履歴を取得
Future<void> loadAnalysisHistory() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await user.getIdToken();

    final response = await http.get(
      Uri.parse(
        'https://asia-northeast1-cocoon-688eb.cloudfunctions.net/getOrganizationAnalysisHistory',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      setState(() {
       analysisHistory = List<Map<String, dynamic>>.from(
  data['history'],
).where((history) => history['isSample'] == false).toList();
      });
    } else {
      debugPrint(
        'AI分析履歴の取得に失敗: ${response.statusCode}',
      );
    }
  } catch (error) {
    debugPrint('AI分析履歴の取得エラー: $error');
  }
}

Future<void> loadRemainingAnalyses() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final idToken = await user.getIdToken();

    if (idToken == null) return;

    final response = await http.get(
      Uri.parse(
        'https://asia-northeast1-cocoon-688eb.cloudfunctions.net/getAnalysisRemaining',
      ),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      setState(() {
        remainingAnalyses = data['remaining'] as int?;
      });
    } else {
      debugPrint(
        '残り回数の取得に失敗しました: ${response.statusCode}',
      );
    }
  } catch (error) {
    debugPrint('残り回数の取得エラー: $error');
  }
}

Future<void> runAiAnalysis() async {
  if (isAnalyzing) return;

  setState(() {
    isAnalyzing = true;
    analysisError = null;
  });

  try {
    // ログイン中の管理者を取得
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('ログインが必要です。');
    }

    // Firebaseの認証トークンを取得
    final idToken = await user.getIdToken();

    if (idToken == null) {
      throw Exception('認証情報を取得できませんでした。');
    }

    // Firebase Cloud Functionsにリクエスト
    final response = await http.post(
      Uri.parse(
        'https://asia-northeast1-cocoon-688eb.cloudfunctions.net/organizationAnalysis',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({}),
    ).timeout(const Duration(seconds: 70));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      if (!mounted) return;

     setState(() {
  aiAnalysis = data['analysis'] as String?;
  remainingAnalyses = data['remaining'] as int?;
});

// AI分析結果をブラウザに保存
final storageKey = analysisStorageKey;
final analysis = aiAnalysis;

if (storageKey != null && analysis != null) {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(storageKey, analysis);
}

await loadAnalysisHistory();
    } else {
      throw Exception(
        data['error'] ?? 'AI分析に失敗しました。',
      );
    }
  } catch (error) {
    if (!mounted) return;

    setState(() {
      analysisError = error.toString().replaceFirst(
        'Exception: ',
        '',
      );
    });
  } finally {
    if (mounted) {
      setState(() {
        isAnalyzing = false;
      });
    }
  }
}

String get organizationAnalysis {
  if (aggregateStatus == 'insufficient_data') {
    return '回答人数が不足しているため、組織の傾向を表示できません。';
  }

  if (aggregateStatus != 'ready') {
    return '集計データを確認中です。';
  }

  return '先週の集計が表示されています。'
      '詳しい分析は「AI分析を実行」から確認できます。';
}

String get improvementActions {
  return '集計結果だけで原因を決めつけず、'
      '従業員の意見も聞きながら職場改善を検討してください。';
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FC),
      
appBar: AppBar(
  title: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [
    const Text(
      'COCOON 企業管理画面',
      style: TextStyle(fontSize: 18),
    ),
    Text(
      organizationName ?? '会社情報を読み込み中...',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
    ),
  ],
),
  backgroundColor: const Color(0xFFEDE2F6),
  foregroundColor: const Color(0xFF49365D),
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'ログアウト',
      onPressed: () async {
        await FirebaseAuth.instance.signOut();

        if (!context.mounted) return;

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      },
    ),
  ],
),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '従業員の心の傾向',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF49365D),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '組織全体の傾向を把握するための画面です。',
          ),
          const SizedBox(height: 24),
Text(
  aggregatePeriod == null
      ? '集計期間を読み込み中...'
      : '集計期間：$aggregatePeriod',
),
const SizedBox(height: 12),

if (aggregateStatus == 'ready') ...[
  _summaryCard(
    '集計対象人数',
    '$participantCount人',
    Icons.people,
  ),
  const SizedBox(height: 12),
  _summaryCard(
    '安心・うれしいの平均',
    '$positiveRate / 100',
    Icons.sentiment_satisfied_alt,
  ),
  const SizedBox(height: 12),
  _summaryCard(
    '疲れの平均',
    '$tiredRate / 100',
    Icons.favorite_border,
  ),
  const SizedBox(height: 8),
  const Text(
    '感情の強さの平均です。人数の割合ではありません。',
    style: TextStyle(
      fontSize: 12,
      color: Colors.grey,
    ),
  ),
] else
  Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        aggregateStatus == 'insufficient_data'
            ? '回答人数が不足しているため集計を表示できません。\n'
              '先週の回答者が10人以上になると表示します。'
            : '集計データを確認中です。',
      ),
    ),
  ),

const SizedBox(height: 24),
 const Card(
  color: Colors.white,
  child: Padding(
    padding: EdgeInsets.all(20),
    child: Text(
      '集計は先週の月曜〜日曜を対象にしています。\n'
      '個人の記録を保護するため、回答者が10人未満の場合は'
      '人数と気分の数値を表示しません。',
    ),
  ),
),

const SizedBox(height: 24),

// 従業員の所属申請一覧
Card(
  color: Colors.white,
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.people_outline,
              color: Color(0xFF9C7BB5),
            ),
            SizedBox(width: 8),
            Text(
              '従業員の所属申請',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF49365D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (isLoadingMembershipRequests)
          const Center(child: CircularProgressIndicator())
        else if (membershipRequestsError != null)
          Text(
            membershipRequestsError!,
            style: const TextStyle(color: Colors.red),
          )
        else if (membershipRequests.isEmpty)
          const Text('現在、承認待ちの申請はありません。')
        else
          ...membershipRequests.map((request) {
            final requestId = request['id']?.toString();
  final employeeName =
      request['employeeName']?.toString() ?? '氏名未登録';

  final createdAt = request['createdAt']?.toString();
  final date = createdAt == null
      ? null
      : DateTime.tryParse(createdAt)?.toLocal();

  final dateText = date == null
      ? '日時不明'
      : '${date.year}/${date.month}/${date.day} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

  return ListTile(
    leading: const Icon(
      Icons.person_outline,
      color: Color(0xFF9C7BB5),
    ),
    title: Text(employeeName),
    subtitle: Text('申請日時：$dateText'),
    trailing: OutlinedButton(
  onPressed: () async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('所属申請の確認'),
      content: Text(
        '$employeeName さんが自社の従業員であることを'
        '社内の情報で確認しましたか？\n\n'
        '確認できていない場合は、承認しないでください。',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(dialogContext, true),
          child: const Text('確認済み'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  if (requestId == null || requestId.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('申請IDを取得できませんでした。'),
    ),
  );
  return;
}

 await approveMembership(requestId);
},
  child: const Text('承認'),
),
  );
}),
           
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: isLoadingMembershipRequests
              ? null
              : loadMembershipRequests,
          icon: const Icon(Icons.refresh),
          label: const Text('申請一覧を更新'),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 24),

Card(
  color: Colors.white,
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Color(0xFF9C7BB5),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'COCOON AI 組織分析',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF49365D),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '今週の組織コンディション',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
       
Text(
  organizationAnalysis,
),

        const Divider(height: 32),
        const Text(
          '💡 職場改善アクション',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
Text(
  improvementActions,
),

if (remainingAnalyses != null) ...[
  Text(
    '本日のAI分析：残り $remainingAnalyses 回',
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color(0xFF49365D),
    ),
  ),
  const SizedBox(height: 12),
],

const SizedBox(height: 20),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: (
  isAnalyzing ||
  remainingAnalyses == 0 ||
  aggregateStatus != 'ready'
)
    ? null
    : runAiAnalysis,
    icon: isAnalyzing
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
        : const Icon(Icons.auto_awesome),
    label: Text(
      isAnalyzing ? 'AI分析中...' : 'AI分析を実行',
    ),
  ),
),

if (analysisError != null) ...[
  const SizedBox(height: 12),
  Text(
    analysisError!,
    style: const TextStyle(color: Colors.red),
  ),
],

if (aiAnalysis != null) ...[
  const SizedBox(height: 16),
  const Text(
    'AIによる分析結果',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
  const SizedBox(height: 8),
  SelectableText(aiAnalysis!),
],

// 過去のAI分析履歴
const SizedBox(height: 24),

const Text(
  '📋 過去のAI分析履歴',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xFF49365D),
  ),
),

const SizedBox(height: 12),

if (analysisHistory.isEmpty)
  const Text('保存された分析履歴はありません。')
else
  ...analysisHistory.map((history) {
    final analysis = history['analysis']?.toString() ?? '';
    final createdAt = history['createdAt']?.toString();
    final date = createdAt != null
        ? DateTime.tryParse(createdAt)?.toLocal()
        : null;

    final dateText = date == null
        ? '日時不明'
        : '${date.year}/${date.month}/${date.day} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';

    return Card(
      color: const Color(0xFFF9F6FC),
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(dateText),
        subtitle: const Text('AI組織分析'),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          SelectableText(analysis),
        ],
      ),
    );
  }),

        const SizedBox(height: 12),
        const Text(
          '※ AI分析には、人数条件を満たした組織全体の集計値のみを使用し、OpenAI APIで分析します。',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  ),
),



          const SizedBox(height: 16),
          const Text(
            '※ 集計には、共有に同意して送信された気分の数値を使用します。\n'
'※ 個人別の記録・メモ本文・チャット内容は表示しません。',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF9C7BB5),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

