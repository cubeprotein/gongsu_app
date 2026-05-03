import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------
// 전역 팔레트 및 상수
// ----------------------------
const Color kSystemBarColor = Color(0xFF1E2A45);
const Color kAppBarColor = Color(0xFF3C486B);
const Color kBodyBackground = Color(0xFFF0F0F0);
const Color kSaveButtonColor = Color(0xFFF9D949);
const Color kDeleteButtonColor = Color(0xFFF45050);
const Color kLeaveActiveColor = Color(0xFF2D6A4F);

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

  bool _isLeave = false;
  bool _isPaidLeave = false; // ✅ 유급 휴무 상태 변수 추가
  static const _weekdayKo = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};

    // 공수 설정
    _workDayCtrl.text = d['workDay']?.toString() ?? '1.0';

    // ✅ 리스크 방지: 기존 데이터 로드시에도 단가에 콤마 포맷팅 적용
    final initialPayRaw = (d['dayPay'] ?? d['unitPrice']);
    if (initialPayRaw != null) {
      final parsed = int.tryParse(initialPayRaw.toString()) ?? 0;
      _dayPayCtrl.text = NumberFormat('#,###').format(parsed);
    } else {
      _dayPayCtrl.text = '';
    }

    _siteNameCtrl.text = d['siteName']?.toString() ?? '';
    _memoCtrl.text = d['memo']?.toString() ?? '';

    // ✅ 휴무 및 유급 상태 초기화
    _isPaidLeave = d['isPaidLeave'] ?? false;
    _isLeave = (d['leave'] == 1) && !_isPaidLeave;

    if (widget.initialData == null) {
      _loadLastInputs();
    }
  }

  // ✅ [기능] 최근 입력값 불러오기 (SiteName, DayPay)
  Future<void> _loadLastInputs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final lastSite = prefs.getString('lastSiteName');
      final lastPay = prefs.getString('lastDayPay');
      if (lastSite != null && _siteNameCtrl.text.isEmpty) {
        _siteNameCtrl.text = lastSite;
      }
      if (lastPay != null && _dayPayCtrl.text.isEmpty) {
        // ✅ 리스크 방지: tryParse를 사용하여 비정상 데이터로 인한 크래시 방지
        final parsedPay = int.tryParse(lastPay);
        if (parsedPay != null) {
          _dayPayCtrl.text = NumberFormat('#,###').format(parsedPay);
        }
      }
    });
  }

  // ✅ [기능] 입력값 저장
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
    return double.tryParse(s.trim()) ?? 0.0;
  }

  int _parseInt(String s) {
    final t = s.replaceAll(',', '').trim();
    return int.tryParse(t) ?? 0;
  }

  void _stepWorkDay(double delta) {
    setState(() {
      if (_isLeave) _isLeave = false;
      if (_isPaidLeave) _isPaidLeave = false; // ✅ 유급 상태도 해제

      double cur = _parseWorkDay(_workDayCtrl.text);
      double next = (cur + delta).clamp(0.0, 20.0);
      _workDayCtrl.text = next == next.toInt()
          ? next.toInt().toString()
          : next.toString();
    });
  }

  void _save() async {
    final workDay = _parseWorkDay(_workDayCtrl.text);
    final dayPay = _parseInt(_dayPayCtrl.text);
    final site = _siteNameCtrl.text.trim();

    // ✅ 휴무나 유급휴무가 아닐 때 필수값 체크
    if (!_isLeave &&
        !_isPaidLeave &&
        (workDay <= 0 || dayPay <= 0 || site.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('현장명, 단가, 공수를 확인해주세요.')));
      return;
    }

    await _saveLastInputs();

    Navigator.pop<Map<String, dynamic>>(context, {
      'workDay': (_isLeave || _isPaidLeave)
          ? 0.0
          : workDay, // ✅ 둘 다 실제 공수는 0.0 저장
      'dayPay': dayPay,
      'siteName': site,
      'memo': _memoCtrl.text.trim(),
      'leave': _isLeave ? 1 : 0, // ✅ 휴무 여부 플래그
      'isPaidLeave': _isPaidLeave, // ✅ 유급 여부 데이터 추가
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSunday = widget.selectedDate.weekday == DateTime.sunday;
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final dow = _weekdayKo[widget.selectedDate.weekday - 1];

    return Scaffold(
      backgroundColor: kBodyBackground,
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        foregroundColor: Colors.white,
        title: const Text("공수 입력"),
        elevation: 0,
        actions: [
          if (widget.initialData != null)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              onPressed: () async {
                final ok = await _showDeleteDialog();
                if (ok == true) Navigator.pop(context, {'__delete__': true});
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$dateStr ($dow)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSunday ? Colors.red : kAppBarColor,
                ),
              ),
              // ✅ 휴무 및 유급 체크박스 행 구성
              Row(
                children: [
                  const Text(
                    '휴무',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Checkbox(
                    value: _isLeave,
                    activeColor: kDeleteButtonColor,
                    onChanged: (val) {
                      setState(() {
                        _isLeave = val ?? false;
                        if (_isLeave) {
                          _workDayCtrl.text = "0.0";
                          _isPaidLeave = false; // 상호 배타적
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 1),
                  const Text(
                    '유급',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Checkbox(
                    value: _isPaidLeave,
                    activeColor: Colors.orange,
                    onChanged: (val) {
                      setState(() {
                        _isPaidLeave = val ?? false;
                        if (_isPaidLeave) {
                          _workDayCtrl.text = "0.0";
                          _isLeave = false; // 상호 배타적
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildLabel('현장명'),
          TextField(
            controller: _siteNameCtrl,
            decoration: _inputDecoration("예: S-oil, GS칼텍스 등"),
          ),
          const SizedBox(height: 16),

          _buildLabel('공수 단가 (원)'),
          TextField(
            controller: _dayPayCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            onChanged: (raw) {
              if (raw.isEmpty) return;
              final formatted = NumberFormat(
                '#,###',
              ).format(int.parse(raw.replaceAll(',', '')));
              _dayPayCtrl.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            },
            decoration: _inputDecoration("단가를 입력하세요"),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // 1. 마이너스 버튼
              _stepButton(Icons.remove, () => _stepWorkDay(-0.5)),

              Expanded(
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // ✅ 휴무 또는 유급일 때 색상 변경
                    color: _isPaidLeave
                        ? Colors.orange
                        : (_isLeave
                              ? kLeaveActiveColor
                              : const Color.fromARGB(255, 250, 208, 19)),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  // ✅ 휴무/유급 시 텍스트 표시 분기
                  child: (_isLeave || _isPaidLeave)
                      ? Text(
                          _isPaidLeave ? "유급" : "휴무",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : TextField(
                          controller: _workDayCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center, // 텍스트 중앙 정렬
                          cursorColor: Colors.black, // 커서 색상
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                ),
              ),

              // 2. 플러스 버튼
              _stepButton(Icons.add, () => _stepWorkDay(0.5)),
            ],
          ),
          const SizedBox(height: 16),

          _buildLabel('공수 직접 입력 (소수점 가능)'),
          TextField(
            controller: _workDayCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: _inputDecoration("0.45, 1.2 등"),
            onChanged: (val) {
              if (_parseWorkDay(val) > 0) {
                setState(() {
                  _isLeave = false;
                  _isPaidLeave = false; // ✅ 수동 입력시 둘 다 해제
                });
              }
            },
          ),
          const SizedBox(height: 16),

          _buildLabel('메모 (선택)'),
          TextField(
            controller: _memoCtrl,
            maxLines: 2,
            decoration: _inputDecoration("특이사항 입력"),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                  255,
                  255,
                  224,
                  85,
                ), // 기존 색상 유지
                foregroundColor: const Color.fromARGB(
                  255,
                  0,
                  0,
                  0,
                ), // 기존 글자색 유지
                shape: const StadiumBorder(),
              ),
              child: const Text(
                "저장하기",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color.fromARGB(189, 189, 189, 189),
      fontSize: 14,
    ),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kAppBarColor, width: 1.5),
    ),
  );

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25), // 터치 시 퍼지는 효과도 타원형으로
      child: Container(
        width: 60, // 버튼 가로 크기
        height: 50, // 버튼 세로 크기 (중앙 입력창 높이와 일치)
        decoration: BoxDecoration(
          color: Colors.white, // 바탕색은 흰색
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.grey.shade300, // 이미지처럼 연한 회색 테두리
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.black, // 아이콘 색상
          size: 24, // 아이콘 크기
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog() => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("삭제"),
      content: const Text("정말 삭제하시겠습니까?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("취소"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("삭제", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
