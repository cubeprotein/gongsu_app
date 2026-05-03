import 'package:flutter/material.dart';
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
          '\n오직 플랜트건설노동자만을 위한 공수 관리 앱입니다.\n실시간 클라우드 동기화를 지원합니다.\n\n-배관 7소대 화이팅-',
        ),
      ],
    );
  }
}
