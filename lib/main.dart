import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

// ✅ 공휴일 매니저 임포트 (경로를 확인해 주세요)
import 'holiday_manager.dart';
import 'screens/login/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 초기화
  await Firebase.initializeApp();
  kakao.KakaoSdk.init(nativeAppKey: '1af73a293a97369b17ea96ad9a6e17c6');

  // 2. 공휴일 동기화 (앱 실행 시 딱 한 번만 수행)
  // ✅ 이제 다른 페이지(SplashPage, CalendarPage 등)의 build 함수 안에서 이 함수를 호출하지 마세요.
  await HolidayManager.syncHolidays();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

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
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF3C486B),
      ),
      home: const SplashPage(),
    );
  }
}
