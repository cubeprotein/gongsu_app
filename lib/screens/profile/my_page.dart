import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';

// --- 추가된 import (경로를 프로젝트 구조에 맞게 확인하세요) ---
import '../calendar/work_calendar_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _formKey = GlobalKey<FormState>();
  
  // 입력 제어를 위한 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 기존 저장된 프로필 불러오기
  Future<void> _loadUserData() async {
    final user = await ProfileService.loadProfile();
    setState(() {
      _nameController.text = user.name;
      _jobController.text = user.jobTitle;
      _siteController.text = user.siteName;
      _roleController.text = user.role;
      _isLoading = false;
    });
  }

  // --- [수정된 부분] 정보 저장 및 동선 제어 ---
  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      final updatedUser = UserModel(
        name: _nameController.text,
        jobTitle: _jobController.text,
        siteName: _siteController.text,
        role: _roleController.text,
      );

      await ProfileService.saveProfile(updatedUser);
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 정보가 저장되었습니다.')),
      );

      // ✅ 검은 화면 방어 로직:
      // 뒤로 갈 곳(달력 화면)이 있다면 pop하고, 
      // 처음 가입/로그인 직후라 뒤로 갈 곳이 없다면 달력 화면으로 이동합니다.
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true); // 사이드바에서 온 경우
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WorkCalendarPage()),
        ); // 로그인 후 처음 온 경우
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("마이페이지", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B263B), // 정시 색상(네이비)
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // 뒤로가기 버튼 자동 생성 방지 (처음 설정 시)
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("내 정보 수정", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              _buildInputField("성함", _nameController, "이름을 입력하세요"),
              _buildInputField("직종", _jobController, "예: 배관기능장, 용접사 등"),
              _buildInputField("현장명", _siteController, "현재 투입 중인 현장명"),
              _buildInputField("담당 업무", _roleController, "예: MD 담당, Spoolman 등"),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B263B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("저장하기", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            ),
            validator: (value) => (value == null || value.isEmpty) ? "$label을 입력해주세요" : null,
          ),
        ],
      ),
    );
  }
}