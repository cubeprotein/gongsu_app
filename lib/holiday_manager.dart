import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HolidayManager {
  static const String _url =
      "https://raw.githubusercontent.com/cubeprotein/gongsu_app/main/holidays.json";

  // 초기 설치 시 통신 전까지 사용할 최소 데이터
  static final Map<String, String> _defaultHolidays = {
    "2026-01-01": "신정",
    "2026-03-01": "삼일절",
    "2026-05-05": "어린이날",
    "2026-08-15": "광복절",
    "2026-10-03": "개천절",
    "2026-10-09": "한글날",
    "2026-12-25": "성탄절",
  };

  // 1. 저장된 데이터 가져오기 (캐시 우선)
  static Future<Map<String, String>> getHolidays() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('holiday_cache');

    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = json.decode(cachedData);
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      } catch (e) {
        return _defaultHolidays;
      }
    }
    return _defaultHolidays;
  }

  // 2. 서버 동기화 (하루 1회 제한 로직 추가)
  static Future<bool> syncHolidays() async {
    final prefs = await SharedPreferences.getInstance();

    // 오늘 날짜 확인 (예: 2026-04-30)
    final String today = DateTime.now().toString().substring(0, 10);
    final String? lastSync = prefs.getString('last_holiday_sync');

    // ✅ 오늘 이미 동기화에 성공했다면 불필요한 통신 차단
    if (lastSync == today) {
      print("📅 오늘 이미 업데이트를 완료했습니다. (중복 호출 방지)");
      return true;
    }

    try {
      print("📡 서버 동기화 시도 중...");
      final response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.isNotEmpty) {
          // 데이터 저장 및 동기화 성공 날짜 기록
          await prefs.setString('holiday_cache', response.body);
          await prefs.setString('last_holiday_sync', today);
          print("✅ 공휴일 데이터 업데이트 성공 (항목 수: ${decoded.length})");
          return true;
        }
      }
    } catch (e) {
      print("⚠️ 동기화 실패: $e");
    }
    return false;
  }
}
