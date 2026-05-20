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
    final stopwatch = Stopwatch()..start();
    User? firebaseUser = FirebaseAuth.instance.currentUser;

    // 1. 핵심 팩트: 메모리에 캐시된 유저가 없다면, 진짜 토큰을 찾아낼 때까지 대기
    if (firebaseUser == null) {
      try {
        // null이 아닌 유저 값이 들어올 때까지 버팀 (최대 3초)
        firebaseUser = await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((user) => user != null)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        // 3초가 지나도 타임아웃이 나면, 진짜로 로그아웃 한 유저로 확정
        firebaseUser = null;
      }
    }

    // 2. 스플래시 화면 최소 노출 시간(2초) 보장 계산
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 2000) {
      await Future.delayed(Duration(milliseconds: 2000 - elapsed));
    }

    if (!mounted) return;

    // 인증 실패 시 로그인 페이지로 강제 이동
    if (firebaseUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    // 데이터 마이그레이션 실행
    try {
      final currentYear = DateTime.now().year;
      await WorkService().migrateOldDataToYearlyStructure(currentYear);
    } catch (e) {
      debugPrint("Migration Error: $e");
    }

    // 프로필 확인 및 캘린더 이동
    try {
      final profile = await ProfileService().loadProfile();
      if (!mounted) return;

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
      debugPrint("Profile Load Error: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WorkCalendarPage()),
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
