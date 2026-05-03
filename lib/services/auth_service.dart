import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 구글 로그인
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } catch (e) {
      print("Google Login Error: $e");
      return null;
    }
  }

  // 카카오 로그인 (Firebase Custom Token 연동)
  Future<User?> signInWithKakao() async {
    try {
      // 1. 카카오 SDK 로그인
      bool isInstalled = await kakao.isKakaoTalkInstalled();
      kakao.OAuthToken token = isInstalled
          ? await kakao.UserApi.instance.loginWithKakaoTalk()
          : await kakao.UserApi.instance.loginWithKakaoAccount();

      // 2. Cloud Functions 호출 (us-central1 지역 명시)
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('kakaoCustomAuth');

      final result = await callable.call({'accessToken': token.accessToken});

      // 3. 반환된 커스텀 토큰으로 Firebase 로그인
      final String customToken = result.data['token'];
      UserCredential userCredential = await _auth.signInWithCustomToken(
        customToken,
      );

      return userCredential.user;
    } catch (e) {
      print("Kakao Firebase Login Error: $e");
      return null;
    }
  }

  // 로그아웃 (통합)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      try {
        await kakao.UserApi.instance.logout();
      } catch (_) {
        // 이미 로그아웃된 경우 등 예외 처리
      }
    } catch (e) {
      print("Logout Error: $e");
    }
  }
}
