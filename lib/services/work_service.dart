import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // 문서 참조 경로 표준화
  DocumentReference _getDocRef(int year, int month) {
    String monthStr = month.toString().padLeft(2, '0');
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('monthly_logs')
        .doc('$year-$monthStr');
  }

  // [핵심] 초고속 로컬 캐시 우선 읽기
  Future<Map<String, dynamic>> _getMonthlyDoc(int year, int month) async {
    if (_uid.isEmpty) return {};
    final docRef = _getDocRef(year, month);

    try {
      DocumentSnapshot doc = await docRef.get(
        const GetOptions(source: Source.cache),
      );
      if (doc.exists) return doc.data() as Map<String, dynamic>;
    } catch (e) {
      // 캐시 없음
    }

    try {
      DocumentSnapshot doc = await docRef.get(
        const GetOptions(source: Source.server),
      );
      return doc.exists ? (doc.data() as Map<String, dynamic>) : {};
    } catch (e) {
      return {};
    }
  }

  // 특정 월의 순수 데이터 반환
  Future<Map<String, dynamic>> getMonthlyData(int year, int month) async {
    return await _getMonthlyDoc(year, month);
  }

  // UI용 데이터 변환 (이제 bonus_config도 함께 반환합니다)
  Future<Map<String, Map<String, dynamic>>> getMonthlyDataForUI(
    int year,
    int month,
  ) async {
    final rawData = await _getMonthlyDoc(year, month);
    Map<String, Map<String, dynamic>> formattedData = {};

    rawData.forEach((key, value) {
      // 날짜 데이터(01, 02...)와 설정 데이터(bonus_config)를 모두 포함시킵니다.
      if (key == 'bonus_config') {
        formattedData[key] = Map<String, dynamic>.from(value as Map);
      } else {
        String fullDateKey =
            "$year-${month.toString().padLeft(2, '0')}-${key.padLeft(2, '0')}";
        formattedData[fullDateKey] = Map<String, dynamic>.from(value as Map);
      }
    });
    return formattedData;
  }

  // 12개월치 통합 데이터 반환
  Future<Map<String, Map<String, dynamic>>> getYearlyData(int year) async {
    final futures = List.generate(12, (i) => getMonthlyDataForUI(year, i + 1));
    final results = await Future.wait(futures);

    Map<String, Map<String, dynamic>> yearlyAll = {};
    for (var monthMap in results) {
      yearlyAll.addAll(monthMap);
    }
    return yearlyAll;
  }

  // 공수 저장
  Future<void> saveWorkLog(String dateKey, Map<String, dynamic> data) async {
    if (_uid.isEmpty) return;
    DateTime date = DateTime.parse(dateKey);
    String dayKey = date.day.toString().padLeft(2, '0');

    await _getDocRef(
      date.year,
      date.month,
    ).set({dayKey: data}, SetOptions(merge: true));
  }

  // ✅ 보너스 설정 저장 (기존 SharedPreferences를 대체)
  Future<void> saveBonusConfig(
    int year,
    int month,
    Map<String, dynamic> config,
  ) async {
    if (_uid.isEmpty) return;
    await _getDocRef(
      year,
      month,
    ).set({'bonus_config': config}, SetOptions(merge: true));
  }

  // 삭제
  Future<void> deleteWorkLog(String dateKey) async {
    if (_uid.isEmpty) return;
    DateTime date = DateTime.parse(dateKey);
    String dayKey = date.day.toString().padLeft(2, '0');

    await _getDocRef(
      date.year,
      date.month,
    ).update({dayKey: FieldValue.delete()});
  }

  // 연간 통계 계산
  Future<Map<String, dynamic>> calculateYearlySummary(int year) async {
    double totalGongsu = 0;
    double totalAmount = 0;

    final List<Map<String, dynamic>> allMonthsRaw = await Future.wait(
      List.generate(12, (i) => getMonthlyData(year, i + 1)),
    );

    for (var monthData in allMonthsRaw) {
      if (monthData.isNotEmpty) {
        final summary = calculateMonthSummaryFromMap(monthData);
        totalGongsu += (summary['totalGongsu'] ?? 0).toDouble();
        totalAmount += (summary['totalAmount'] ?? 0).toDouble();
      }
    }
    return {'totalGongsu': totalGongsu, 'totalAmount': totalAmount};
  }

  // 요약 계산 로직
  Map<String, dynamic> calculateMonthSummaryFromMap(
    Map<String, dynamic> monthlyData,
  ) {
    double dailyGongsu = 0;
    double dailyAmount = 0;

    monthlyData.forEach((key, value) {
      if (key == 'bonus_config') return;
      final data = Map<String, dynamic>.from(value as Map);
      final wd = double.tryParse(data['workDay']?.toString() ?? '0') ?? 0.0;
      final dp = num.tryParse(data['dayPay']?.toString() ?? '0') ?? 0;
      final adj = double.tryParse(data['adjustment']?.toString() ?? '0') ?? 0.0;
      dailyGongsu += wd;
      dailyAmount += (wd * dp) + adj;
    });

    final bonus = monthlyData['bonus_config'] as Map<String, dynamic>? ?? {};
    final base = bonus['basePay'] ?? 0;
    final w = double.tryParse(bonus['weeklyDays']?.toString() ?? '0') ?? 0.0;
    final m = double.tryParse(bonus['monthlyDays']?.toString() ?? '0') ?? 0.0;
    final e = double.tryParse(bonus['efficiency']?.toString() ?? '0') ?? 0.0;

    return {
      'totalGongsu': dailyGongsu + w + m + e,
      'totalAmount': dailyAmount + ((w + m + e) * base),
    };
  }
}
