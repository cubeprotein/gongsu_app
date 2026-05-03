import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/work_service.dart';
import 'bonus_setting_dialog.dart';

const Color kAppBarColor = Color(0xFF3C486B);

class WorkCalendarBottomSummary extends StatefulWidget {
  final Map<String, Map<String, dynamic>> workData;
  final DateTime focusedMonth;
  final bool isPremium;
  final VoidCallback onRefresh;

  const WorkCalendarBottomSummary({
    super.key,
    required this.workData,
    required this.focusedMonth,
    required this.isPremium,
    required this.onRefresh,
  });

  @override
  State<WorkCalendarBottomSummary> createState() =>
      _WorkCalendarBottomSummaryState();
}

class _WorkCalendarBottomSummaryState extends State<WorkCalendarBottomSummary> {
  final _workService = WorkService();

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
    _syncBonusFromWorkData();
  }

  @override
  void didUpdateWidget(covariant WorkCalendarBottomSummary oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool monthChanged =
        oldWidget.focusedMonth.year != widget.focusedMonth.year ||
        oldWidget.focusedMonth.month != widget.focusedMonth.month;

    final bool dataChanged = oldWidget.workData != widget.workData;

    if (monthChanged || dataChanged) {
      if (monthChanged) _resetPeriod();
      _syncBonusFromWorkData();
    }
  }

  void _syncBonusFromWorkData() {
    final bonus = widget.workData['bonus_config'] ?? {};
    setState(() {
      basePay = bonus['basePay'] ?? 0;
      weeklyDays = (bonus['weeklyDays'] ?? 0.0).toDouble();
      monthlyDays = (bonus['monthlyDays'] ?? 0.0).toDouble();
      efficiency = (bonus['efficiency'] ?? 0).toInt();
      taxRate = (bonus['taxRate'] ?? 0.0).toDouble();
    });
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

  Future<void> _saveBonusToFirestore() async {
    final config = {
      'basePay': basePay.toInt(),
      'weeklyDays': weeklyDays,
      'monthlyDays': monthlyDays,
      'efficiency': efficiency,
      'taxRate': taxRate,
    };

    // [수정1] 기간(startDate) 상관없이 반드시 '현재 보고 있는 달(focusedMonth)'의 DB에 저장합니다.
    await _workService.saveBonusConfig(
      widget.focusedMonth.year,
      widget.focusedMonth.month,
      config,
    );
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

      await _saveBonusToFirestore();
      widget.onRefresh();
    }
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

  @override
  Widget build(BuildContext context) {
    double workDaySum = 0;
    int amountSum = 0;
    double regularSum = 0;
    double overtimeSum = 0;
    double earlyLeaveSum = 0;

    widget.workData.forEach((key, value) {
      if (key == 'bonus_config') return;
      final date = DateTime.tryParse(key);
      if (date == null || startDate == null || endDate == null) return;
      if (date.isBefore(startDate!) || date.isAfter(endDate!)) return;

      final double workDay = (value['workDay'] as num?)?.toDouble() ?? 0.0;
      final int dayPay = (value['dayPay'] as num?)?.toInt() ?? 0;
      final double adj = (value['adjustment'] as num?)?.toDouble() ?? 0.0;
      final bool isPaidLeave = value['isPaidLeave'] == true; // ✅ 유급 휴무 확인

      // ✅ 유급 휴무일 경우 실 공수에 1.0 강제 추가
      double effectiveWorkDay = workDay;
      if (isPaidLeave) {
        effectiveWorkDay += 1.0;
      }

      workDaySum += effectiveWorkDay;
      amountSum += ((dayPay * effectiveWorkDay) + adj).round();

      // ✅ 정시/잔업/조퇴 계산 로직에도 유급 휴무(1공수)가 반영되도록 수정
      if (effectiveWorkDay >= 1) {
        regularSum += 1;
        if (effectiveWorkDay > 1) overtimeSum += (effectiveWorkDay - 1);
      } else if (effectiveWorkDay > 0) {
        earlyLeaveSum += effectiveWorkDay;
      }
    });

    final bonusDays = weeklyDays + monthlyDays + efficiency;
    final totalWorkDays = workDaySum + bonusDays;

    final totalAmount = amountSum + (bonusDays * basePay).round();

    final taxAmount = (totalAmount * (taxRate / 100)).round();
    final netAmount = (totalAmount - taxAmount).round();

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "기간",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
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
                  if (picked != null) setState(() => startDate = picked);
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    "~",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
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
                      const Text(
                        "능률",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "$efficiency",
                              style: const TextStyle(color: Color(0xFF4480E7)),
                            ),
                            const TextSpan(
                              text: "개  ",
                              style: TextStyle(color: Colors.black),
                            ),
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.add_circle,
                                size: 20,
                                color: Color.fromARGB(255, 55, 203, 1),
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatBox(
                "정시",
                const Color(0xFF1B263B),
                "${regularSum.toStringAsFixed(1)}일",
              ),
              _buildStatBox(
                "잔업",
                const Color(0xFFC62828),
                "${overtimeSum.toStringAsFixed(2)}일",
              ),
              _buildStatBox(
                "조퇴",
                const Color(0xFFFBC02D),
                "${earlyLeaveSum.toStringAsFixed(1)}일",
              ),
              _buildStatBox(
                "주/월",
                const Color(0xFF645282),
                "${weeklyDays.toInt()}/${monthlyDays.toInt()}개",
                onTap: _openBonusDialog,
              ),
            ],
          ),
          Divider(height: 10, thickness: 1.2, color: Colors.grey.shade300),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          const TextSpan(text: "총 공수 "),
                          TextSpan(
                            text: totalWorkDays.toStringAsFixed(2),
                            style: const TextStyle(color: Colors.blue),
                          ),
                          const TextSpan(text: "일     합계 "),
                          TextSpan(
                            text: NumberFormat('#,###').format(totalAmount),
                            style: const TextStyle(color: Color(0xFF2D6A4F)),
                          ),
                          const TextSpan(text: "원"),
                        ],
                      ),
                    ),
                    if (taxRate > 0) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          "세액($taxRate%): -${NumberFormat('#,###').format(taxAmount)}원",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: "실 수령액 ",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text:
                                    "${NumberFormat('#,###').format(netAmount)}원",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD53A2F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(DateTime date, Future<void> Function() onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          DateFormat("MM.dd").format(date),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
