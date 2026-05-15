import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  DocumentReference _getYearlyDocRef(int year) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('yearly_logs')
        .doc('$year');
  }

  Future<Map<String, dynamic>> _getYearlyDoc(int year) async {
    if (_uid.isEmpty) return {};
    final docRef = _getYearlyDocRef(year);

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

  Future<Map<String, Map<String, dynamic>>> getMonthlyDataForUI(
    int year,
    int month,
  ) async {
    final yearlyData = await _getYearlyDoc(year);
    Map<String, Map<String, dynamic>> monthlyData = {};

    String monthPrefix = "$year-${month.toString().padLeft(2, '0')}-";
    String bonusKey = "bonus_config_${month.toString().padLeft(2, '0')}";

    yearlyData.forEach((key, value) {
      if (key.startsWith(monthPrefix)) {
        monthlyData[key] = Map<String, dynamic>.from(value as Map);
      } else if (key == bonusKey) {
        monthlyData['bonus_config'] = Map<String, dynamic>.from(value as Map);
      }
    });

    return monthlyData;
  }

  Future<Map<String, Map<String, dynamic>>> getYearlyData(int year) async {
    final rawData = await _getYearlyDoc(year);
    Map<String, Map<String, dynamic>> formattedData = {};

    rawData.forEach((key, value) {
      formattedData[key] = Map<String, dynamic>.from(value as Map);
    });
    return formattedData;
  }

  Future<void> saveWorkLog(String dateKey, Map<String, dynamic> data) async {
    if (_uid.isEmpty) return;
    DateTime date = DateTime.parse(dateKey);

    await _getYearlyDocRef(
      date.year,
    ).set({dateKey: data}, SetOptions(merge: true));
  }

  Future<void> saveBonusConfig(
    int year,
    int month,
    Map<String, dynamic> config,
  ) async {
    if (_uid.isEmpty) return;
    String monthStr = month.toString().padLeft(2, '0');

    await _getYearlyDocRef(
      year,
    ).set({'bonus_config_$monthStr': config}, SetOptions(merge: true));
  }

  Future<void> deleteWorkLog(String dateKey) async {
    if (_uid.isEmpty) return;
    DateTime date = DateTime.parse(dateKey);

    await _getYearlyDocRef(date.year).update({dateKey: FieldValue.delete()});
  }

  Future<Map<String, dynamic>> calculateYearlySummary(int year) async {
    double totalGongsu = 0;
    double totalAmount = 0;

    final yearlyData = await _getYearlyDoc(year);

    for (int m = 1; m <= 12; m++) {
      String monthPrefix = "$year-${m.toString().padLeft(2, '0')}-";
      String bonusKey = "bonus_config_${m.toString().padLeft(2, '0')}";

      Map<String, dynamic> monthTempData = {};
      yearlyData.forEach((key, value) {
        if (key.startsWith(monthPrefix)) {
          monthTempData[key] = value;
        } else if (key == bonusKey) {
          monthTempData['bonus_config'] = value;
        }
      });

      if (monthTempData.isNotEmpty) {
        final summary = calculateMonthSummaryFromMap(monthTempData);
        totalGongsu += (summary['totalGongsu'] ?? 0).toDouble();
        totalAmount += (summary['totalAmount'] ?? 0).toDouble();
      }
    }
    return {'totalGongsu': totalGongsu, 'totalAmount': totalAmount};
  }

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

  // 일회성 마이그레이션 함수
  Future<void> migrateOldDataToYearlyStructure(int year) async {
    if (_uid.isEmpty) return;

    final yearlyDoc = await _getYearlyDocRef(year).get();
    if (yearlyDoc.exists) return; // 중복 실행 방지

    Map<String, dynamic> combinedYearlyData = {};

    for (int month = 1; month <= 12; month++) {
      String monthStr = month.toString().padLeft(2, '0');
      DocumentSnapshot oldDoc = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('monthly_logs')
          .doc('$year-$monthStr')
          .get();

      if (oldDoc.exists && oldDoc.data() != null) {
        Map<String, dynamic> oldData = oldDoc.data() as Map<String, dynamic>;

        oldData.forEach((key, value) {
          if (key == 'bonus_config') {
            combinedYearlyData['bonus_config_$monthStr'] = value;
          } else {
            String fullDateKey = "$year-$monthStr-${key.padLeft(2, '0')}";
            combinedYearlyData[fullDateKey] = value;
          }
        });
      }
    }

    if (combinedYearlyData.isNotEmpty) {
      await _getYearlyDocRef(year).set(combinedYearlyData);
    }
  }
}
