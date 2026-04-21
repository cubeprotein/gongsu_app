import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// --- 추가된 import (경로 확인 필요) ---
import 'services/profile_service.dart';
import 'screens/profile/my_page.dart';
import 'screens/calendar/work_calendar_page.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바와 하단 바 설정
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const GongsuApp());
}

// 🎨 색상 정의
class AppColors {
  static const Color mainBlue = Color(0xFF3C486B);
  static const Color backgroundWhite = Colors.white;
  static const Color kakaoYellow = Color(0xFFFEE500);
}

class GongsuApp extends StatelessWidget {
  const GongsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '플랜트공수',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate, // 수정: GlobalCupertinoLocalizations 대체 가능
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundWhite,
        primaryColor: AppColors.mainBlue,
      ),
      home: const SplashPage(),
    );
  }
}

// ----------------------------------------------------
// 1️⃣ 웰컴 화면 (자동 로그인 로직 적용)
// ----------------------------------------------------
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final List<String> greetings = [
    '안전하게 퇴근하세요 🏠', '오늘도 행복한 하루! 😊', '당신은 정말 최고예요! 👍',
    '오늘도 안전제일 👷', '당신을 응원합니다 ❤️', '오늘도 1공수 추가요! 💰',
    '당신을 존경합니다', '서두르지 말고 안전하게!', '오늘도 다치지 마세요 🩹',
    '웃으면 복이 와요 ✨', '건강이 최고!', '어제보다 더 나은 오늘! 🚀',
    '우리 집 영웅, 파이팅! 🦸', '오늘도 보너스 가득한 날!', '기쁘게 퇴근!',
    '거의 다 왔어요! 🏁', '오늘도 당신을 응원합니다', '안전 귀가!',
    '오늘도 파이팅! 🔥', '고생 많으셨습니다.',
  ];

  late String selectedGreeting;

  @override
  void initState() {
    super.initState();
    selectedGreeting = greetings[Random().nextInt(greetings.length)];

    // 2초 후 자동 로그인 여부 확인 및 이동
    Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      
      // 저장된 프로필 확인
      final user = await ProfileService.loadProfile();
      
      if (!mounted) return;

      // 이름이 기본값("홍길동")이 아니고 비어있지 않다면 자동 로그인 처리
      if (user.name != "홍길동" && user.name.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WorkCalendarPage()),
        );
      } else {
        // 정보가 없으면 로그인 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/app_logo.png', width: 200, height: 200),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    selectedGreeting,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainBlue,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 2️⃣ 로그인 페이지 (동선 분기 로직 적용)
// ----------------------------------------------------
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // 버튼 클릭 시 실행될 동선 제어 함수
  void _handleLoginSuccess(BuildContext context) async {
    final user = await ProfileService.loadProfile();

    if (!context.mounted) return;

    // 프로필 정보가 없으면 마이페이지로, 있으면 달력으로
    if (user.name == "홍길동" || user.name.isEmpty) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
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
                  color: AppColors.mainBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              _buildLoginButton(
                text: '카카오로 시작하기',
                color: AppColors.kakaoYellow,
                textColor: Colors.black87,
                onPressed: () => _handleLoginSuccess(context),
              ),
              const SizedBox(height: 12),
              _buildLoginButton(
                text: 'Google로 시작하기',
                color: Colors.white,
                textColor: Colors.black87,
                isOutlined: true,
                onPressed: () => _handleLoginSuccess(context),
              ),
              const SizedBox(height: 12),
              _buildLoginButton(
                text: '이메일로 시작하기',
                color: AppColors.mainBlue,
                textColor: Colors.white,
                onPressed: () => _handleLoginSuccess(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: isOutlined ? 0 : 1,
        side: isOutlined ? const BorderSide(color: Colors.black26) : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}