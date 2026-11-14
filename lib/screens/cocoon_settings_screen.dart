import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CocoonSettingsScreen extends StatefulWidget {
  const CocoonSettingsScreen({super.key});

  @override
  State<CocoonSettingsScreen> createState() =>
      _CocoonSettingsScreenState();
}

class _CocoonSettingsScreenState
    extends State<CocoonSettingsScreen> {
  bool shareTimeline = false;
  bool shareProfile = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      shareTimeline =
          prefs.getBool('shareTimeline') ?? false;
      shareProfile =
          prefs.getBool('shareProfile') ?? false;
      isLoading = false;
    });
  }

  Future<void> updateShareTimeline(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('shareTimeline', value);

    if (!mounted) return;

    setState(() {
      shareTimeline = value;
    });
  }

  Future<void> updateShareProfile(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('shareProfile', value);

    if (!mounted) return;

    setState(() {
      shareProfile = value;
    });
  }

  Widget sharingSetting({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(description),
        value: value,
        activeTrackColor: const Color(0xFFD9C5ED),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: const Color(0xFFF8F3FA),
        foregroundColor: const Color(0xFF655472),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'AIチャットの設定',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF655472),
                  ),
                ),
                const SizedBox(height: 16),
                sharingSetting(
                  title: 'わたし年表をルナと共有する',
                  description:
                      'ONにすると、年表に登録した出来事を'
                      'AIチャットの返答に活用できます。\n'
                      'OFFにすると、年表データの新たな送信を停止します。',
                  value: shareTimeline,
                  onChanged: updateShareTimeline,
                ),
                const SizedBox(height: 16),
                sharingSetting(
                  title: 'あなたのことをルナと共有する',
                  description:
                      'ONにすると、ニックネーム・兄弟姉妹・'
                      '生活の状況・好きなこと・苦手なこと・'
                      '希望するサポートを、返答の参考として'
                      'AIサービスに送信します。\n'
                      '生年月日は、この設定では送信しません。\n'
                      'OFFにすると、プロフィールデータの'
                      '新たな送信を停止します。',
                  value: shareProfile,
                  onChanged: updateShareProfile,
                ),
                const SizedBox(height: 16),
                const Text(
                  'どちらも初期設定はOFFです。\n'
                  '共有するかどうかはいつでも変更できます。\n\n'
                  'OFFにしても、すでに会話に含まれた情報や'
                  '過去に送信した情報は削除されません。'
                  '会話履歴に含まれた情報は、以後の返答でも'
                  '参照される場合があります。',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF756B7A),
                  ),
                ),
              ],
            ),
    );
  }
}
