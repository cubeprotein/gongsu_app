import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class DailyWorkInputDialog extends StatefulWidget {
  final DateTime date;
  final Map<String, dynamic>? initialData;

  const DailyWorkInputDialog({super.key, required this.date, this.initialData});

  @override
  State<DailyWorkInputDialog> createState() => _DailyWorkInputDialogState();
}

class _DailyWorkInputDialogState extends State<DailyWorkInputDialog> {
  // 컨트롤러들
  late TextEditingController _workDayController; // 공수(1, 0.7 등)
  late TextEditingController _dayPayController; // 일당(원) - 기존 unitPrice 호환
  late TextEditingController _siteNameController; // 현장명
  late TextEditingController _adjustController; // 조정치(옵션)
  late TextEditingController _leaveController; // 월차(옵션)
  late TextEditingController _memoController; // ✅ 메모 추가

  @override
  void initState() {
    super.initState();

    // 초기값 매핑 (legacy 호환: unitPrice → dayPay)
    final init = widget.initialData ?? {};
    final initWorkDay = init['workDay']?.toString() ?? '';
    final initDayPay = (init['dayPay'] ?? init['unitPrice'])?.toString() ?? '';
    final initSite = init['siteName']?.toString() ?? '';
    final initAdj = init['adjustment']?.toString() ?? '';
    final initLeave = init['leave']?.toString() ?? '';
    final initMemo = init['memo']?.toString() ?? ''; // ✅ 메모 초기값

    _workDayController = TextEditingController(text: initWorkDay);
    _dayPayController = TextEditingController(text: initDayPay);
    _siteNameController = TextEditingController(text: initSite);
    _adjustController = TextEditingController(text: initAdj);
    _leaveController = TextEditingController(text: initLeave);
    _memoController = TextEditingController(text: initMemo); // ✅ 메모 초기화
  }

  @override
  void dispose() {
    _workDayController.dispose();
    _dayPayController.dispose();
    _siteNameController.dispose();
    _adjustController.dispose();
    _leaveController.dispose();
    _memoController.dispose(); // ✅ 메모 해제
    super.dispose();
  }

  /// 숫자 (천단위 콤마 허용, 공백 트림)
  num? _parseNum(String s) {
    if (s.trim().isEmpty) return null;
    final cleaned = s.replaceAll(',', '').trim();
    return num.tryParse(cleaned);
  }

  /// 정수 (빈 값이면 0)
  int _parseIntOrZero(String s) {
    final n = _parseNum(s);
    return n == null ? 0 : n.toInt();
  }

  /// 실수  (빈 값이면 0.0)
  double _parseDoubleOrZero(String s) {
    final n = _parseNum(s);
    return n == null ? 0.0 : n.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy년 MM월 dd일').format(widget.date);

    return AlertDialog(
      title: Text('$formattedDate 공수 입력'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 공수(1, 0.7 등)
            TextField(
              controller: _workDayController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '공수',
                hintText: '예: 1 / 0.7',
              ),
            ),
            const SizedBox(height: 8),

            // 🔹 일당(원) — dayPay (콤마 입력 허용, 저장 시 콤마 제거)
            TextField(
              controller: _dayPayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '일당 (원)',
                hintText: '예: 100000',
              ),
            ),
            const SizedBox(height: 8),

            // 🔹 현장명
            TextField(
              controller: _siteNameController,
              decoration: const InputDecoration(
                labelText: '현장명',
                hintText: '예: 현장명',
              ),
            ),
            const SizedBox(height: 12),

            // (옵션) 조정치: 공수 보정치 (+/-)
            TextField(
              controller: _adjustController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '조정치 (옵션)',
                hintText: '예: 0.2 또는 -0.3',
              ),
            ),
            const SizedBox(height: 8),

            // (옵션) 월차: 정수
            TextField(
              controller: _leaveController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '월차 (옵션, 일수)',
                hintText: '예: 1',
              ),
            ),
            const SizedBox(height: 8),

            // ✅ (옵션) 메모 추가
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모 (옵션)',
                hintText: '예: 야간 연장, 특이사항 등',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // 취소 시 null 반환
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            // 유효성 검사
            final workDay = _parseNum(_workDayController.text)?.toDouble();
            final dayPay = _parseNum(_dayPayController.text)?.toInt();
            final siteName = _siteNameController.text.trim();

            if (workDay == null || dayPay == null || siteName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('공수, 일당, 현장명을 정확히 입력하세요')),
              );
              return;
            }

            // (옵션) 조정치/월차/메모 처리
            final adjustment = _parseDoubleOrZero(_adjustController.text);
            final leave = _parseIntOrZero(_leaveController.text);
            final memo = _memoController.text.trim(); // ✅ 메모 가져오기

            // Map으로 반환
            Navigator.of(context).pop({
              'workDay': workDay,
              'dayPay': dayPay,
              'siteName': siteName,
              'adjustment': adjustment,
              'leave': leave,
              'memo': memo, // ✅ 반환 데이터에 메모 포함
            });
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
