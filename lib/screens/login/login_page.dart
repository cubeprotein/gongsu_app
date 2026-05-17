import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../calendar/work_calendar_page.dart';
import '../profile/my_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _onLoginSuccess(
    BuildContext context,
    firebase_auth.User firebaseUser,
  ) async {
    // 1. 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. 서버 동기화 대기 (0.5초)
      await Future.delayed(const Duration(milliseconds: 500));

      final userProfile = await ProfileService().loadProfile();

      if (!context.mounted) return;
      Navigator.pop(context); // 로딩창 닫기

      // 3. 판정 조건: 이름만 있으면 통과
      final bool isNameInvalid =
          userProfile.name.trim().isEmpty || userProfile.name == "홍길동";

      Widget nextPage;
      if (isNameInvalid) {
        nextPage = const MyPage();
      } else {
        nextPage = const WorkCalendarPage();
      }

      // 4. [수정] LoginWelcomeScreen 없이 바로 다음 페이지로 이동 (에러 해결)
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('프로필 정보를 가져오지 못했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '환영합니다!\n로그인하고 시작하세요.',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C486B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            _buildLoginButton(
              text: '카카오로 시작하기',
              color: const Color(0xFFFEE500),
              textColor: Colors.black,
              onPressed: () async {
                final user = await auth.signInWithKakao();
                if (user != null && context.mounted) {
                  _onLoginSuccess(context, user);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildLoginButton(
              text: 'Google로 시작하기',
              color: const Color(0xFF4285F4),
              textColor: Colors.white,
              onPressed: () async {
                final user = await auth.signInWithGoogle();
                if (user != null && context.mounted) {
                  _onLoginSuccess(context, user);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
