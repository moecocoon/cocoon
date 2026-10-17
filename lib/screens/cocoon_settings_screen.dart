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

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'わたし年表をルナと共有する',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'ONにすると、年表に登録した出来事を'
                      'AIチャットの返答に活用できます。\n'
                      '共有をOFFにすると、以後のチャットでは'
                      '年表を送信しません。',
                    ),
                    value: shareTimeline,
                    activeTrackColor:
                        const Color(0xFFD9C5ED),
                    onChanged: updateShareTimeline,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  '初期設定はOFFです。\n'
                  '年表には個人的な情報が含まれるため、'
                  '共有するかどうかはいつでも変更できます。',
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
