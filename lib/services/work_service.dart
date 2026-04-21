import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WorkService {
  static const String _storageKey = 'workData';

  // [프로의 팁] 날짜 키를 항상 2026-04-01 형태로 일정하게 만들어주는 도구
  static String formatDateKey(String dateKey) {
    try {
      DateTime parsed = DateTime.parse(dateKey);
      return "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateKey; // 형식이 안 맞으면 그대로 반환
    }
  }

  // 1. 전체 데이터 로드
  static Future<Map<String, Map<String, dynamic>>> loadAllWorkData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return {};

    try {
      final decoded = jsonDecode(jsonString);
      return Map<String, Map<String, dynamic>>.from(
        (decoded as Map).map(
          (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
        ),
      );
    } catch (e) {
      print('데이터 로드 에러: $e');
      return {};
    }
  }

  // 2. 데이터 저장 (날짜 키 표준화 적용)
  static Future<void> saveWorkLog(
    String dateKey,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final currentData = await loadAllWorkData();

    // 저장할 때 무조건 2026-04-01 형식을 갖추도록 강제함
    String standardKey = formatDateKey(dateKey);
    currentData[standardKey] = data;

    await prefs.setString(_storageKey, jsonEncode(currentData));
  }

  // 3. 데이터 삭제
  static Future<void> deleteWorkLog(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final currentData = await loadAllWorkData();
    String standardKey = formatDateKey(dateKey);

    if (currentData.containsKey(standardKey)) {
      currentData.remove(standardKey);
      await prefs.setString(_storageKey, jsonEncode(currentData));
    }
  }

  // 4. 연간 통계용 데이터 필터링 (정교한 필터링)
  static Future<Map<String, Map<String, dynamic>>> getYearlyData(
    int year,
  ) async {
    final allData = await loadAllWorkData();
    // 2026- 로 시작하는 것들만 안전하게 추출
    return Map.fromEntries(
      allData.entries.where((entry) => entry.key.startsWith('$year-')),
    );
  }
}
