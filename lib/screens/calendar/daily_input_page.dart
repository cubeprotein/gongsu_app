import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------
// 전역 팔레트 색상 상수 정의
// ----------------------------
const Color kSystemBarColor = Color(0xFF1E2A45);
const Color kAppBarColor = Color(0xFF3C486B);
const Color kBodyBackground = Color(0xFFF0F0F0);
const Color kSaveButtonColor = Color(0xFFF9D949);
const Color kDeleteButtonColor = Color(0xFFF45050);
const Color kLeaveActiveColor = Color(0xFF2D6A4F); // 휴무 활성 색상 (회색)

void setCustomSystemBar() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: kSystemBarColor,
      statusBarIconBrightness: Brightness.light,
    ),
  );
}

class DailyInputPage extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, dynamic>? initialData;

  const DailyInputPage({
    super.key,
    required this.selectedDate,
    this.initialData,
  });

  @override
  State<DailyInputPage> createState() => _DailyInputPageState();
}

class _DailyInputPageState extends State<DailyInputPage> {
  final _workDayCtrl = TextEditingController();
  final _dayPayCtrl = TextEditingController();
  final _siteNameCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  bool _isLeave = false; // ✅ 휴무 여부 상태 추가

  static const _weekdayKo = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    setCustomSystemBar();
    final d = widget.initialData ?? {};
    _workDayCtrl.text = (d['workDay']?.toString() ?? '1.0');
    _dayPayCtrl.text = (d['dayPay'] ?? d['unitPrice'])?.toString() ?? '';
    _siteNameCtrl.text = d['siteName']?.toString() ?? '';
    _memoCtrl.text = d['memo']?.toString() ?? '';

    // 초기 데이터에 휴무 정보가 있다면 반영 (int 1이면 true로 가정)
    _isLeave = d['leave'] == 1;

    _loadLastInputs();
  }

  Future<void> _loadLastInputs() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSite = prefs.getString('lastSiteName');
    final lastPay = prefs.getString('lastDayPay');
    if (lastSite != null && lastSite.isNotEmpty && _siteNameCtrl.text.isEmpty) {
      _siteNameCtrl.text = lastSite;
    }
    if (lastPay != null && lastPay.isNotEmpty && _dayPayCtrl.text.isEmpty) {
      final formatted = NumberFormat('#,###').format(int.parse(lastPay));
      _dayPayCtrl.text = formatted;
    }
  }

  Future<void> _saveLastInputs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSiteName', _siteNameCtrl.text.trim());
    await prefs.setString('lastDayPay', _dayPayCtrl.text.replaceAll(',', ''));
  }

  @override
  void dispose() {
    _workDayCtrl.dispose();
    _dayPayCtrl.dispose();
    _siteNameCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  double _parseWorkDay(String s) {
    final v = double.tryParse(s.trim()) ?? 0.0;
    return v.clamp(0.0, 10.0);
  }

  int _parseInt(String s) {
    final t = s.replaceAll(',', '').trim();
    return int.tryParse(t) ?? 0;
  }

  bool _validate() {
    // 휴무일 때는 공수가 0이어도 저장 가능하도록 예외 처리 가능
    if (_isLeave) return true;

    final workDay = _parseWorkDay(_workDayCtrl.text);
    final dayPay = _parseInt(_dayPayCtrl.text);
    final site = _siteNameCtrl.text.trim();
    return workDay > 0 && dayPay > 0 && site.isNotEmpty;
  }

  void _save() async {
    if (!_validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공수·단가·현장명을 정확히 입력하세요')));
      return;
    }
    if (!_isLeave) {
      await _saveLastInputs();
    }

    Navigator.pop<Map<String, dynamic>>(context, {
      'workDay': _isLeave ? 0.0 : _parseWorkDay(_workDayCtrl.text),
      'dayPay': _parseInt(_dayPayCtrl.text),
      'siteName': _siteNameCtrl.text.trim(),
      'memo': _memoCtrl.text.trim(),
      'adjustment': 0.0,
      'leave': _isLeave ? 1 : 0, // ✅ 휴무 여부 1/0으로 전달
    });
  }

  void _stepWorkDay(double delta) {
    setState(() {
      if (_isLeave) _isLeave = false; // ✅ 증감 버튼 클릭 시 휴무 해제
      final cur = _parseWorkDay(_workDayCtrl.text);
      final next = (cur + delta).clamp(0.0, 10.0);
      _workDayCtrl.text = next.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final y = widget.selectedDate.year.toString().padLeft(4, '0');
    final m = widget.selectedDate.month.toString().padLeft(2, '0');
    final d = widget.selectedDate.day.toString().padLeft(2, '0');
    final dateStr = "$y-$m-$d";
    final dow = _weekdayKo[widget.selectedDate.weekday - 1];

    return Scaffold(
      backgroundColor: kBodyBackground,
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        foregroundColor: Colors.white,
        title: const Text("공수입력"),
        actions: [
          if (widget.initialData != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: kDeleteButtonColor,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('삭제'),
                      content: const Text('해당 날짜의 공수를 삭제할까요?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) Navigator.pop(context, {'__delete__': true});
                },
                child: const Text('삭제'),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ 날짜와 휴무 체크박스 라인
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$dateStr ($dow)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kAppBarColor,
                ),
              ),
              Row(
                children: [
                  const Text(
                    '휴무',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Checkbox(
                    value: _isLeave,
                    activeColor: kDeleteButtonColor, // 체크 시 빨간색 계열
                    onChanged: (val) {
                      setState(() {
                        _isLeave = val ?? false;
                        if (_isLeave) {
                          _workDayCtrl.text = "0.0"; // 휴무 체크 시 공수 0.0
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 1),

          const Text('현장', style: TextStyle(fontSize: 16, color: Colors.black)),
          const SizedBox(height: 6),
          TextField(
            controller: _siteNameCtrl,
            decoration: InputDecoration(
              isDense: true, // 1. 세로폭 압축
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ), // 2. 내부 여백 조절
              hintText: "예) 현장 이름",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: kAppBarColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: kAppBarColor, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Text(
            '공수 단가',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _dayPayCtrl,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (raw) {
              if (raw.isEmpty) return;
              final digitsOnly = raw.replaceAll(',', '');
              final formatted = NumberFormat(
                '#,###',
              ).format(int.parse(digitsOnly));
              _dayPayCtrl.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            },
            decoration: InputDecoration(
              isDense: true, // ✅ 추가
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ), // ✅ 추가
              hintText: "금액을 입력하세요",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              suffix: Padding(
                padding: const EdgeInsets.only(
                  right: 10,
                ), // ✅ 우측 벽에서 15만큼 안쪽으로 밀어넣음
                child: const Text(
                  "원",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // 숫자 크기에 맞춰 약간 키우면 더 보기 좋습니다.
                  ),
                ),
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: kAppBarColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: kAppBarColor, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 18),
          // ✅ 공수 증감 영역 (휴무 상태 시 UI 변경)
          Row(
            children: [
              _pillButton(icon: Icons.remove, onTap: () => _stepWorkDay(-0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isLeave
                        ? kLeaveActiveColor
                        : const Color.fromARGB(255, 247, 185, 1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color.fromARGB(255, 189, 189, 189),
                    ),
                  ),
                  child: Text(
                    _isLeave
                        ? '휴무'
                        : (_workDayCtrl.text.isEmpty
                              ? '0.0'
                              : _parseWorkDay(
                                  _workDayCtrl.text,
                                ).toStringAsFixed(1)),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _isLeave ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _pillButton(icon: Icons.add, onTap: () => _stepWorkDay(0.5)),
            ],
          ),

          const SizedBox(height: 10),
          const Text(
            '공수 직접 입력',
            style: TextStyle(fontSize: 15, color: Colors.black),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _workDayCtrl,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: "0.45 , 1.7 같은 (소수점도 입력 가능)",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: kAppBarColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: kAppBarColor, width: 2),
              ),
              isDense: true,
            ),
            onChanged: (val) {
              setState(() {
                if (_parseWorkDay(val) > 0) _isLeave = false;
              });
            },
          ),

          const SizedBox(height: 10),
          const Text(
            '메모 (선택)',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _memoCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "오늘 하루는.....",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: kAppBarColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: kAppBarColor, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kSaveButtonColor,
                foregroundColor: Colors.black,
              ),
              onPressed: _save,
              child: const Text(
                '저장',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: 56,
      height: 44,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: Colors.grey.shade400),
          backgroundColor: Colors.white,
        ),
        child: Icon(icon, color: Colors.black),
      ),
    );
  }
}
