import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bonus_setting_dialog.dart';

// ----------------------------
// 전역 팔레트 색상 상수 정의
// ----------------------------
const Color kAppBarColor = Color(0xFF3C486B); // 메인 네이비

class WorkCalendarBottomSummary extends StatefulWidget {
  final Map<String, Map<String, dynamic>> workData;
  final DateTime focusedMonth;
  final bool isPremium;

  const WorkCalendarBottomSummary({
    super.key,
    required this.workData,
    required this.focusedMonth,
    required this.isPremium,
  });

  @override
  State<WorkCalendarBottomSummary> createState() =>
      _WorkCalendarBottomSummaryState();
}

class _WorkCalendarBottomSummaryState extends State<WorkCalendarBottomSummary> {
  num basePay = 0;
  double weeklyDays = 0.0;
  double monthlyDays = 0.0;
  int efficiency = 0;
  double taxRate = 0.0;

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _resetPeriod();
    _loadBonusValuesForDate(startDate!);
  }

  @override
  void didUpdateWidget(covariant WorkCalendarBottomSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedMonth != widget.focusedMonth) {
      _resetPeriod();
      _loadBonusValuesForDate(startDate!);
    }
  }

  void _resetPeriod() {
    setState(() {
      startDate = DateTime(
        widget.focusedMonth.year,
        widget.focusedMonth.month,
        1,
      );
      endDate = DateTime(
        widget.focusedMonth.year,
        widget.focusedMonth.month + 1,
        0,
      );
    });
  }

  Widget _datePickerThemeBuilder(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        datePickerTheme: DatePickerThemeData(
          headerBackgroundColor: kAppBarColor,
          headerForegroundColor: Colors.white,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          dayStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        colorScheme: const ColorScheme.light(
          primary: kAppBarColor,
          onSurface: Colors.black,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kAppBarColor,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      child: child!,
    );
  }

  Future<void> _saveBonusValuesForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'bonus_${date.year}_${date.month}';
    await prefs.setInt('${key}_basePay', basePay.toInt());
    await prefs.setDouble('${key}_weeklyDays', weeklyDays);
    await prefs.setDouble('${key}_monthlyDays', monthlyDays);
    await prefs.setInt('${key}_efficiency', efficiency);
    await prefs.setDouble('${key}_taxRate', taxRate);
  }

  Future<void> _loadBonusValuesForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'bonus_${date.year}_${date.month}';
    setState(() {
      basePay = prefs.getInt('${key}_basePay') ?? 0;
      weeklyDays = prefs.getDouble('${key}_weeklyDays') ?? 0.0;
      monthlyDays = prefs.getDouble('${key}_monthlyDays') ?? 0.0;
      efficiency = prefs.getInt('${key}_efficiency') ?? 0;
      taxRate = prefs.getDouble('${key}_taxRate') ?? 0.0;
    });
  }

  Future<void> _openBonusDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BonusSettingDialog(
        initialBasePay: basePay.toInt(),
        initialWeeklyDays: weeklyDays,
        initialMonthlyDays: monthlyDays,
        initialEfficiency: efficiency,
        initialTaxRate: taxRate,
      ),
    );

    if (result != null) {
      setState(() {
        basePay = result['basePay'] ?? basePay;
        weeklyDays = result['weeklyDays'] ?? weeklyDays;
        monthlyDays = result['monthlyDays'] ?? monthlyDays;
        efficiency = result['efficiency'] ?? efficiency;
        taxRate = result['taxRate'] ?? taxRate;
      });
      if (startDate != null) {
        await _saveBonusValuesForDate(startDate!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double workDaySum = 0;
    int amountSum = 0;
    double regularSum = 0;
    double overtimeSum = 0;
    double earlyLeaveSum = 0;

    widget.workData.forEach((key, value) {
      final date = DateTime.tryParse(key);
      if (date == null || startDate == null || endDate == null) return;
      if (date.isBefore(startDate!) || date.isAfter(endDate!)) return;

      final double workDay = (value['workDay'] as num?)?.toDouble() ?? 0.0;
      final int dayPay = (value['dayPay'] as num?)?.toInt() ?? 0;

      workDaySum += workDay;
      amountSum += (dayPay * workDay).round();

      if (workDay >= 1) {
        regularSum += 1;
        if (workDay > 1) overtimeSum += (workDay - 1);
      } else if (workDay > 0) {
        earlyLeaveSum += workDay;
      }
    });

    final bonusSum = ((weeklyDays + monthlyDays + efficiency) * basePay).round();
    final totalAmount = amountSum + bonusSum;
    final netAmount = (totalAmount * (1 - taxRate / 100)).round();
    final totalWorkDays = workDaySum + weeklyDays + monthlyDays + efficiency;

    return Container(
      // 1. 배경색 투명화 (부모 카드색 사용) 및 패딩 압축
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- 1단: 기간 및 능률 (FittedBox로 가로 터짐 방지) ---
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("기간", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                _buildDateBox(startDate!, () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate!,
                    firstDate: DateTime(2020),
                    lastDate: endDate ?? DateTime(2050),
                    locale: const Locale("ko", "KR"),
                    builder: _datePickerThemeBuilder,
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                    await _loadBonusValuesForDate(picked);
                  }
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text("~", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                _buildDateBox(endDate!, () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate!,
                    firstDate: startDate ?? DateTime(2020),
                    lastDate: DateTime(2050),
                    locale: const Locale("ko", "KR"),
                    builder: _datePickerThemeBuilder,
                  );
                  if (picked != null) setState(() => endDate = picked);
                }),
                const SizedBox(width: 15),
                GestureDetector(
                  onTap: _openBonusDialog,
                  child: Row(
                    children: [
                      const Text("능률", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: "$efficiency", style: const TextStyle(color: Color(0xFF4480E7))),
                            const TextSpan(text: "개", style: TextStyle(color: Colors.black)),
                          ],
                        ),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10), // 세로 간격 다이어트

          // --- 2단: 상세 통계 (박스 크기 최적화) ---
          Row(
            children: [
              _buildStatBox("정시", const Color(0xFF1B263B), "${regularSum.toStringAsFixed(1)}일"),
              _buildStatBox("잔업", const Color(0xFFC62828), "${overtimeSum.toStringAsFixed(1)}일"),
              _buildStatBox("조퇴", const Color(0xFFFBC02D), "${earlyLeaveSum.toStringAsFixed(1)}일"),
              _buildStatBox("주/월", const Color(0xFF645282), "${weeklyDays.toInt()}/${monthlyDays.toInt()}개", onTap: _openBonusDialog),
            ],
          ),

          // --- 3단: 구분선 (요청하신 부분) ---
          Divider( height: 20, thickness: 1.5,color: Colors.grey,),

          // --- 4단: 총 공수 및 합계 ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  text: "총 공수 ",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(text: totalWorkDays.toStringAsFixed(2), style: const TextStyle(color: Colors.blue)),
                    const TextSpan(text: "일   합계 "),
                    TextSpan(
                      text: NumberFormat('#,###').format(netAmount),
                      style: const TextStyle(color: Color(0xFFD53A2F)),
                    ),
                    const TextSpan(text: "원"),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // --- 5단: 세금 상세 (여기에 추가됨) ---
          if (taxRate > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12), // 합계 글자보다 살끔 안으로 밀어 넣음
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "세액(${taxRate}%): -${NumberFormat('#,###').format((totalAmount * (taxRate / 100)).round())}원",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ], // Column의 자식 리스트 끝
      ),
    );
  }

  Widget _buildDateBox(DateTime date, Future<void> Function() onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // 패딩 다이어트
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          DateFormat("MM.dd").format(date),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), // 폰트 다이어트
        ),
      ),
    );
  }

  Widget _buildStatBox(
    String title,
    Color color,
    String displayValue, {
    Future<void> Function()? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap != null ? () => onTap() : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2), // 마진 축소
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4), // 내부 패딩 축소
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayValue,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}