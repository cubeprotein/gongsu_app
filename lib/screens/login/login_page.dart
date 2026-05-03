import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // 추가
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../calendar/work_calendar_page.dart';
import '../profile/my_page.dart';
import 'login_welcome_screen.dart'; // 추가

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // 파라미터에 firebase_auth.User 추가
  void _onLoginSuccess(
    BuildContext context,
    firebase_auth.User firebaseUser,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userProfile = await ProfileService().loadProfile();

      if (!context.mounted) return;
      Navigator.pop(context); // 로딩창 닫기

      final bool isNameEmpty =
          userProfile.name.isEmpty || userProfile.name == "홍길동";
      final bool isRoleEmpty = userProfile.role.isEmpty;
      final bool isJobEmpty = userProfile.jobTitle.isEmpty;

      // 이동할 다음 화면 결정
      Widget nextPage;
      if (isNameEmpty || isRoleEmpty || isJobEmpty) {
        nextPage = const MyPage();
      } else {
        nextPage = const WorkCalendarPage();
      }

      // 바로 이동하지 않고 웰컴 화면으로 거쳐감
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LoginWelcomeScreen(user: firebaseUser, nextPage: nextPage),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터 로드 실패: $e')));
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
                if (user != null && context.mounted)
                  _onLoginSuccess(context, user);
              },
            ),
            const SizedBox(height: 12),
            _buildLoginButton(
              text: 'Google로 시작하기',
              color: const Color(0xFF4285F4),
              textColor: Colors.white,
              onPressed: () async {
                final user = await auth.signInWithGoogle();
                if (user != null && context.mounted)
                  _onLoginSuccess(context, user);
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
