import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // [추가] 구글 로그아웃을 위해 필요
import 'login_page.dart';

class LoginWelcomeScreen extends StatelessWidget {
  final User user;
  final Widget nextPage;

  const LoginWelcomeScreen({
    super.key,
    required this.user,
    required this.nextPage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                "${user.displayName ?? '반장'}님, 반갑습니다!",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "공수 데이터를 안전하게 동기화할까요?",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => nextPage),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "네, 시작합니다",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              // [수정된 로그아웃 버튼]
              TextButton(
                onPressed: () async {
                  // 1. 파이어베이스 로그아웃
                  await FirebaseAuth.instance.signOut();
                  // 2. 구글 로그인 세션까지 완전히 로그아웃 (이래야 다시 누를 때 계정 선택창이 뜸)
                  await GoogleSignIn().signOut();

                  if (!context.mounted) return;

                  // 3. 로그인 페이지로 이동
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text(
                  "다른 계정으로 로그인",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
