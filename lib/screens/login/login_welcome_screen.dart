import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/profile_service.dart';
import '../../services/work_service.dart';
import '../calendar/work_calendar_page.dart';
import '../profile/my_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final List<String> greetings = [
    '안전하게 퇴근하세요 🏠',
    '오늘도 행복한 하루! 😊',
    '당신은 최고예요! 👍',
    '오늘도 안전제일 👷',
    '당신을 응원합니다 ❤️',
    '오늘도 1공수 추가요! 💰',
    '당신을 존경합니다',
    '서두르지 말고 안전하게!',
    '오늘도 다치지 마세요 🩹',
    '웃으면 복이 와요 ✨',
    '건강이 최고!',
    '어제보다 더 나은 오늘! 🚀',
    '우리 집 영웅, 파이팅! 🦸',
    '보너스 가득한 날!',
    '기쁘게 퇴근!',
    '거의 다 왔어요! 🏁',
    '안전 귀가!',
    '오늘도 파이팅! 🔥',
    '고생 많으셨습니다.',
  ];

  late String selectedGreeting;

  @override
  void initState() {
    super.initState();
    selectedGreeting = greetings[Random().nextInt(greetings.length)];
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // 1. 최소 2초 대기 (스플래시 노출 및 시스템 안정화 시간 확보)
      await Future.delayed(const Duration(seconds: 2));

      // 2. 파이어베이스 인증 상태 확인 (currentUser와 Stream을 모두 활용하는 가장 확실한 방법)
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      firebaseUser ??= await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(milliseconds: 2500), onTimeout: () => null);

      if (!mounted) return;

      // 3. 유저가 없으면 로그인 페이지로 이동
      if (firebaseUser == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      }

      // 4. 데이터 로드 및 마이그레이션 (개별 에러가 나더라도 앱 실행은 유지)
      try {
        final currentYear = DateTime.now().year;
        await WorkService().migrateOldDataToYearlyStructure(currentYear);
      } catch (e) {
        debugPrint("Migration Error: $e");
      }

      final profile = await ProfileService().loadProfile();
      if (!mounted) return;

      // 5. 프로필 상태에 따른 최종 페이지 이동
      // 이름이 비어있거나 기본값일 때만 마이페이지로, 그 외엔 무조건 캘린더로 이동
      if (profile.name.trim().isEmpty || profile.name == "홍길동") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WorkCalendarPage()),
        );
      }
    } catch (e) {
      // 예상치 못한 전체 로직 에러 시 안전하게 로그인 페이지로 유도
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.engineering,
                size: 100,
                color: Color(0xFF3C486B),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              selectedGreeting,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C486B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
