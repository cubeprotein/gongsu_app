import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 📌 애드몹 패키지 추가
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../profile/my_page.dart';
import '../login/login_page.dart';
import '../calendar/year_statistics_page.dart';
import '../tax/tax_statement_page.dart';

class WorkCalendarDrawer extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onProfileUpdate;
  final double totalGongsu;
  final int totalPreTax;
  final DateTime focusedMonth;

  const WorkCalendarDrawer({
    super.key,
    required this.user,
    required this.onProfileUpdate,
    required this.totalGongsu,
    required this.totalPreTax,
    required this.focusedMonth,
  });

  // 📌 보상형 광고 로드 및 재생 함수
  void _loadAndShowRewardedAd(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      ),
    );

    RewardedAd.load(
      adUnitId: 'ca-app-pub-9971528273045316/3119252420', // 제공해주신 광고 ID 적용
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          Navigator.pop(context); // 로딩 다이얼로그 닫기

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
              _showSnackBar(context, "광고 재생에 실패했습니다. 다시 시도해 주세요.");
            },
          );

          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              _showSnackBar(context, "☕ 따뜻한 후원 감사합니다! 큰 힘이 됩니다 투쟁.");
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          Navigator.pop(context); // 로딩 다이얼로그 닫기
          _showSnackBar(context, "현재 시청 가능한 광고가 없습니다. 잠시 후 시도해 주세요.");
        },
      ),
    );
  }

  // 안내용 스낵바 알림 함수
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B263B),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 📌 풀스크린 사선 분할 유도 팝업창
  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;

        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: Stack(
              children: [
                // 1️⃣ [1층: 밑바닥 배경] 남색 빈 도화지
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color(0xFF1B263B),
                  ),
                ),

                // 2️⃣ [2층: 중간 덮개] 빨간색 사선 + 광고 텍스트 영역
                ClipPath(
                  clipper: FullScreenDiagonalClipper(),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _loadAndShowRewardedAd(context);
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color.fromARGB(255, 236, 51, 9),
                      child: SafeArea(
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: screenSize.height * 0.15,
                              right: screenSize.width * 0.1,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Icon(
                                  Icons.local_cafe,
                                  color: Colors.white,
                                  size: 60,
                                ),
                                SizedBox(height: 25),
                                Text(
                                  "오늘 하루도\n현장에서 살아남느라\n고생 많으셨습니다!",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 26,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  "30초 지원 사격으로\n공수투쟁을 응원해 주세요",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: Colors.yellow,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 40),
                                Text(
                                  "👉 화면을 터치하면 광고가 재생됩니다",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3️⃣ [3층: 최상단] '닫기' 글자 레이어 (흐리고, 슬프고, 초라하게 수정완료)
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30, left: 30),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.close,
                              color: Colors.white38,
                              size: 18,
                            ), // 작고 흐리게
                            SizedBox(width: 6),
                            Text(
                              "나중에 하기",
                              style: TextStyle(
                                color: Colors.white38, // 쨍쨍한 흰색 버리고 반투명으로
                                fontSize: 14, // 크기 축소
                                fontWeight: FontWeight.w400, // 굵기 빼기
                                // 그림자 제거 완료
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            _buildUserHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: "마이페이지",
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyPage()),
                      );
                      if (result == true) {
                        onProfileUpdate();
                      }
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.calculate_outlined,
                    title: "세금 내역서",
                    color: Colors.black,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaxStatementPage(
                            selectedMonth: focusedMonth,
                            totalGongsu: totalGongsu,
                            totalPreTax: totalPreTax,
                            user: user,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.local_cafe_outlined,
                    title: "개발자 커피 한잔",
                    color: Colors.black,
                    onTap: () {
                      Navigator.pop(context);
                      _showSupportDialog(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.calendar_month_outlined,
                    title: "연간 공수 통계",
                    color: const Color.fromARGB(255, 236, 51, 9),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              YearStatisticsPage(year: DateTime.now().year),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildMenuItem(
                    icon: Icons.question_answer_outlined,
                    title: "자주 묻는 질문",
                    onTap: () {
                      Navigator.pop(context);
                      _showFAQ(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: "문의하기",
                    onTap: () {
                      Navigator.pop(context);
                      _showInquiry(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: "앱 정보",
                    onTap: () {
                      Navigator.pop(context);
                      _showAppInfo(context);
                    },
                  ),
                  const Divider(),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: "로그아웃",
                    color: const Color.fromARGB(255, 0, 0, 0),
                    onTap: () async {
                      await ProfileService().logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    final name = user?.name ?? "정보 없음";
    final job = user?.jobTitle ?? "미설정";
    final site = user?.siteName ?? "현장 미설정";
    final role = user?.role ?? "업무 미설정";

    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 10, bottom: 20),
      decoration: const BoxDecoration(color: Color(0xFF1B263B)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$name 님",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    job,
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "$site | $role",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF1B263B)),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: color),
      ),
      onTap: onTap,
    );
  }

  void _showFAQ(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '자주 묻는 질문',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFAQTile(
                  '데이터 저장 및 동기화',
                  '입력하신 공수 데이터는 클라우드에 안전하게 저장되어 기기를 변경해도 유지됩니다.',
                ),
                _buildFAQTile(
                  '앱 삭제 시 데이터',
                  '로그인 기반 서비스로 앱을 삭제해도 데이터는 사라지지 않습니다. 재설치 후 로그인하시면 복구됩니다.',
                ),
                _buildFAQTile(
                  '공수 계산 방식',
                  '입력하신 (공수 x 단가)에 설정하신 주차/월차/능률 수당을 더하여 계산됩니다.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTile(String q, String a) {
    return ExpansionTile(
      title: Text(
        q,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Text(a, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  void _showInquiry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문의하기'),
        content: const Text(
          '불편한 점이나 개선 제안은 아래 이메일로 보내주세요.\n\n📧 cubeprotein@gmail.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '플랜트공수',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.engineering,
        size: 32,
        color: Color(0xFF1B263B),
      ),
      applicationLegalese: '© 2026 Master Craftsman Developer',
      children: [
        const Text(
          '\n플랜트건설노동자를 위한 공수 관리 앱입니다.\n실시간 클라우드 동기화를 지원합니다.\n\n-배관 7소대 화이팅-',
        ),
      ],
    );
  }
}

// ✂️ 기기 해상도에 비례하여 화면을 사선으로 쪼개는 커스텀 클리퍼
class FullScreenDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width * 0.4, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height * 0.3);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
