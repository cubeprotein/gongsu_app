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
