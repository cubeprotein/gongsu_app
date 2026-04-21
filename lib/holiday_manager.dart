import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HolidayManager {
  static const String _url =
      "https://raw.githubusercontent.com/yellallio/gongsu_app/main/holidays.json";

  // 1️⃣ 폰에 저장된 공휴일 가져오기
  static Future<Map<String, String>> getHolidays() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('holiday_cache');

    if (cachedData != null) {
      return Map<String, String>.from(json.decode(cachedData));
    }

    // 💡 테스트용: 4월 15일을 강제로 빨간 날(수요일인데 휴일!)로 만듭니다.
    return {"2026-04-15": "테스트공휴일", "2026-05-05": "어린이날", "2026-06-03": "지방선거"};
  }

  // 2️⃣ 서버 동기화
  static Future<void> syncHolidays() async {
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toString().substring(0, 10);

    try {
      final response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        await prefs.setString('holiday_cache', response.body);
        await prefs.setString('last_holiday_check', today);
      }
    } catch (e) {
      print("서버 연결 실패 - 기존 데이터 유지");
    }
  }
}
