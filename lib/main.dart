import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'dart:ui'; // PlatformDispatcher 사용을 위해 필요
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// ✅ 공휴일 매니저 임포트 (경로를 확인해 주세요)
import 'holiday_manager.dart';
import 'screens/login/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 파이어베이스 및 카카오 SDK 최우선 초기화 (로그인 세션 복구 보장)
  await Firebase.initializeApp();
  kakao.KakaoSdk.init(nativeAppKey: '1af73a293a97369b17ea96ad9a6e17c6');

  // --- 👇 [여기서부터 새로 추가된 크래시리틱스 코드] 👇 ---

  // 플러터 프레임워크 자체에서 발생하는 치명적 에러 자동 수집
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // 비동기(Async) 작업 중 발생하는 백그라운드 에러 자동 수집
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // --- 👆 [여기까지 추가됨] 👆 ---

  // 2. 애드몹 엔진 초기화 제거 (인증 간섭 원천 차단 -> WorkCalendarPage 내부로 이동)

  // 3. 공휴일 동기화 (앱 실행 시 딱 한 번만 수행)
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
  return null; // 기존 앱 실행 코드
}

class GongsuApp extends StatelessWidget {
  const GongsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공수투쟁',
      debugShowCheckedModeBanner: false,

      // ✅ 글자 크기 락(Lock) 방어 로직 추가
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);

        // 기기 설정 글자 크기가 커져도 최대 1.15배까지만 허용 (화면 붕괴 원천 차단)
        final scale = mediaQueryData.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.15,
        );

        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: scale),
          child: child!,
        );
      },

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
