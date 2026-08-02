import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {
  final nicknameController = TextEditingController();
  final birthdayController = TextEditingController();
  final siblingController = TextEditingController();
  final lifestyleController = TextEditingController();
  final likesController = TextEditingController();
  final dislikesController = TextEditingController();
  final supportController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    nicknameController.text =
        prefs.getString('profileNickname') ?? '';

    birthdayController.text =
        prefs.getString('profileBirthday') ?? '';

    siblingController.text =
        prefs.getString('profileSibling') ?? '';

    lifestyleController.text =
        prefs.getString('profileLifestyle') ?? '';

    likesController.text =
        prefs.getString('profileLikes') ?? '';

    dislikesController.text =
        prefs.getString('profileDislikes') ?? '';

    supportController.text =
        prefs.getString('profileSupport') ?? '';

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'profileNickname',
      nicknameController.text.trim(),
    );

    await prefs.setString(
      'profileBirthday',
      birthdayController.text.trim(),
    );

    await prefs.setString(
      'profileSibling',
      siblingController.text.trim(),
    );

    await prefs.setString(
      'profileLifestyle',
      lifestyleController.text.trim(),
    );

    await prefs.setString(
      'profileLikes',
      likesController.text.trim(),
    );

    await prefs.setString(
      'profileDislikes',
      dislikesController.text.trim(),
    );

    await prefs.setString(
      'profileSupport',
      supportController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('あなたのことを保存しました'),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF8E7BBE),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Color(0xFF8E7BBE),
          width: 1.5,
        ),
      ),
    );
  }

  Widget profileField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: inputDecoration(
          label: label,
          hint: hint,
          icon: icon,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nicknameController.dispose();
    birthdayController.dispose();
    siblingController.dispose();
    lifestyleController.dispose();
    likesController.dispose();
    dislikesController.dispose();
    supportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F3FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'あなたのこと',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF655472),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8E7BBE),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF2E8FA),
                            Color(0xFFFFEEF4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ルナにあなたのことを教えてね',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF655472),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '入力した内容は、この端末の中に保存されます。',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF817387),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      '基本のこと',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF655472),
                      ),
                    ),

                    const SizedBox(height: 12),

                    profileField(
                      controller: nicknameController,
                      label: 'ニックネーム',
                      hint: '例：もえ',
                      icon: Icons.person_rounded,
                    ),

                    profileField(
                      controller: birthdayController,
                      label: '生年月日',
                      hint: '例：2002年4月1日',
                      icon: Icons.cake_rounded,
                    ),

                    profileField(
                      controller: siblingController,
                      label: 'きょうだい構成',
                      hint: '例：長女、真ん中、一人っ子',
                      icon: Icons.groups_rounded,
                    ),

                    profileField(
                      controller: lifestyleController,
                      label: '今の生活',
                      hint: '例：会社員、学生、休職中',
                      icon: Icons.home_work_rounded,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      '好きなこと・苦手なこと',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF655472),
                      ),
                    ),

                    const SizedBox(height: 12),

                    profileField(
                      controller: likesController,
                      label: '好きなこと',
                      hint: '例：犬、音楽、静かな場所',
                      icon: Icons.favorite_rounded,
                      maxLines: 3,
                    ),

                    profileField(
                      controller: dislikesController,
                      label: '苦手なこと',
                      hint: '例：人混み、強い言い方、電話',
                      icon: Icons.cloud_rounded,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      '困ったときのこと',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF655472),
                      ),
                    ),

                    const SizedBox(height: 12),

                    profileField(
                      controller: supportController,
                      label: '困ったときにしてほしいこと',
                      hint: '例：まず話を聞いてほしい',
                      icon: Icons.volunteer_activism_rounded,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF8E7BBE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: saveProfile,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text(
                          '保存する',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}