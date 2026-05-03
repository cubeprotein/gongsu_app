import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../calendar/work_calendar_page.dart'; // ✅ 이동할 목적지 주소만 추가했습니다.

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController(); // 전화번호용
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _payController = TextEditingController();

  bool _isLoading = true;
  String _currentUid = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _profileService.loadProfile();
      if (!mounted) return;
      setState(() {
        _currentUid = user.uid;
        _nameController.text = user.name;
        _jobController.text = user.jobTitle;
        _siteController.text = user.siteName;
        _roleController.text = user.role;
        _payController.text = user.defaultDayPay == 0
            ? ""
            : user.defaultDayPay.toString();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final currentUser = await _profileService.loadProfile();

        final updatedUser = UserModel(
          uid: _currentUid,
          name: _nameController.text.trim(),
          jobTitle: _jobController.text.trim(), // 전화번호
          siteName: _siteController.text.trim(),
          role: _roleController.text.trim(), // 분회(직종)
          defaultDayPay: currentUser.defaultDayPay,
        );

        await _profileService.saveProfile(updatedUser);

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필 정보가 저장되었습니다.')));

        // ✅ 딱 이 부분만 수정했습니다: pop 대신 달력 페이지로 이동
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WorkCalendarPage()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
        title: const Text(
          "마이페이지",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInputField("성함", _nameController, "홍길동"),
              _buildInputField("분회(직종)", _roleController, "배관, 용접 등"),
              _buildInputField(
                "전화번호",
                _jobController,
                "010-1234-5678",
                inputType: TextInputType.phone,
              ),
              _buildInputField(
                "현장(선택)",
                _siteController,
                "현재 현장명",
                isRequired: false,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B263B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "저장하기",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isRequired = true,
    TextInputType? inputType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: inputType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
            ),
            validator: (value) =>
                isRequired && (value == null || value.trim().isEmpty)
                ? "$label을 입력해주세요"
                : null,
          ),
        ],
      ),
    );
  }
}
