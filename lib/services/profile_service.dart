import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class ProfileService {
  static const String _profileKey = 'user_profile';

  // 1. 유저 정보 저장
  static Future<void> saveProfile(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(user.toMap());
    await prefs.setString(_profileKey, jsonString);
  }

  // 2. 유저 정보 로드
  static Future<UserModel> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_profileKey);

    if (jsonString == null) {
      return UserModel(); // 데이터 없으면 기본값 반환
    }

    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    return UserModel.fromMap(decoded);
  }

  // 3. [추가된 부분] 로그아웃 로직
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // 저장된 유저 프로필 데이터를 삭제하여 초기 상태로 만듭니다.
    await prefs.remove(_profileKey);
  }
}