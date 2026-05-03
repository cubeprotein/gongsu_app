import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../services/work_service.dart';
import 'export_report_modal.dart';

class TaxStatementPage extends StatefulWidget {
  final DateTime selectedMonth;
  final double totalGongsu;
  final int totalPreTax;
  final UserModel? user;

  const TaxStatementPage({
    super.key,
    required this.selectedMonth,
    required this.totalGongsu,
    required this.totalPreTax,
    this.user,
  });

  @override
  State<TaxStatementPage> createState() => _TaxStatementPageState();
}

class _TaxStatementPageState extends State<TaxStatementPage> {
  final GlobalKey _repaintKey = GlobalKey();
  final _workService = WorkService();

  late DateTime _currentMonth;
  late double _currentGongsu;
  late int _currentPreTax;

  // 도움말 상태 관리 변수
  bool showFourHelp = false;
  bool showTaxHelp = false;
  bool showUnionHelp = false;

  bool isFourInsured = true;
  bool isTax33 = false;
  bool isUnionMember = false;

  final Map<String, double> defaultRates = {
    "국민연금": 4.5,
    "건강보험": 3.545,
    "고용보험": 0.9,
    "요양보험": 12.95,
    "근로소득": 3.0,
    "지방소득": 0.3,
    "노조비": 1.0,
  };

  Map<String, double> rates = {
    "국민연금": 0.0,
    "건강보험": 0.0,
    "고용보험": 0.0,
    "요양보험": 0.0,
    "근로소득": 0.0,
    "지방소득": 0.0,
    "노조비": 0.0,
  };

  final Map<String, TextEditingController> _controllers = {
    "국민연금": TextEditingController(),
    "건강보험": TextEditingController(),
    "고용보험": TextEditingController(),
    "요양보험": TextEditingController(),
    "근로소득": TextEditingController(),
    "지방소득": TextEditingController(),
    "노조비": TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedMonth;
    _currentGongsu = widget.totalGongsu;
    _currentPreTax = widget.totalPreTax;
    _initControllersText();
    _loadLocalData();
    _fetchMonthlyWorkData();
  }

  void _initControllersText() {
    for (var l in ["국민연금", "건강보험", "고용보험", "요양보험"]) {
      _controllers[l]!.text = isFourInsured
          ? defaultRates[l]!.toString()
          : (rates[l]! > 0 ? rates[l]!.toString() : "");
    }
    for (var l in ["근로소득", "지방소득"]) {
      _controllers[l]!.text = isTax33
          ? defaultRates[l]!.toString()
          : (rates[l]! > 0 ? rates[l]!.toString() : "");
    }
    _controllers["노조비"]!.text = isUnionMember
        ? defaultRates["노조비"]!.toString()
        : (rates["노조비"]! > 0 ? rates["노조비"]!.toString() : "");
  }

  String get _monthKey => "tax_${_currentMonth.year}_${_currentMonth.month}";

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + offset,
        1,
      );
    });
    _loadLocalData();
    _fetchMonthlyWorkData();
  }

  Future<void> _fetchMonthlyWorkData() async {
    final rawData = await _workService.getMonthlyData(
      _currentMonth.year,
      _currentMonth.month,
    );

    final summary = _workService.calculateMonthSummaryFromMap(rawData);

    if (mounted) {
      setState(() {
        _currentGongsu = (summary['totalGongsu'] ?? 0.0).toDouble();
        _currentPreTax = (summary['totalAmount'] ?? 0).toInt();
      });
    }
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_monthKey);
    if (data != null) {
      final decoded = jsonDecode(data);
      setState(() {
        isFourInsured = decoded['isFourInsured'] ?? true;
        isTax33 = decoded['isTax33'] ?? false;
        isUnionMember = decoded['isUnionMember'] ?? false;
        if (decoded['rates'] != null) {
          rates = Map<String, double>.from(decoded['rates']);
        }
      });
      _initControllersText();
    }
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'isFourInsured': isFourInsured,
      'isTax33': isTax33,
      'isUnionMember': isUnionMember,
      'rates': rates,
    };
    await prefs.setString(_monthKey, jsonEncode(data));
  }

  void _updateState(VoidCallback fn) {
    setState(fn);
    _saveLocalData();
  }

  // 그룹 체크/해제 시 텍스트필드 자동 비움 처리 로직
  void _onGroupToggle(String group, bool isChecked) {
    _updateState(() {
      List<String> targetLabels = [];
      if (group == 'four') {
        isFourInsured = isChecked;
        targetLabels = ["국민연금", "건강보험", "고용보험", "요양보험"];
      } else if (group == 'tax') {
        isTax33 = isChecked;
        targetLabels = ["근로소득", "지방소득"];
      } else if (group == 'union') {
        isUnionMember = isChecked;
        targetLabels = ["노조비"];
      }

      for (var l in targetLabels) {
        if (isChecked) {
          _controllers[l]!.text = defaultRates[l]!.toString();
        } else {
          _controllers[l]!.clear(); // 텍스트 싹 비우기
          rates[l] = 0.0; // 요율 0으로 초기화
        }
      }
    });
  }

  double _getActiveRate(String label, bool isChecked) {
    return isChecked ? defaultRates[label]! : (rates[label] ?? 0.0);
  }

  Future<void> _showExport() async {
    RenderRepaintBoundary boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ExportReportModal(title: "세금 내역서", capturedImage: pngBytes),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "세금 내역서",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white),
            onPressed: _showExport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: _repaintKey,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildDateSection(),
                _buildSummarySection(),
                const Divider(
                  thickness: 4,
                  height: 4,
                  color: Color(0xFFF5F5F5),
                ),
                _buildFourInsuranceGroup(),
                const Divider(
                  thickness: 4,
                  height: 4,
                  color: Color(0xFFF5F5F5),
                ),
                _buildTaxGroup(),
                const Divider(
                  thickness: 4,
                  height: 4,
                  color: Color(0xFFF5F5F5),
                ),
                _buildUnionGroup(),
                const Divider(
                  thickness: 4,
                  height: 4,
                  color: Color(0xFFF5F5F5),
                ),
                _buildNetPaySection(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 24),
          onPressed: () => _changeMonth(-1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            " ${_currentMonth.year}년 ${_currentMonth.month}월 ",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 24),
          onPressed: () => _changeMonth(1),
        ),
      ],
    ),
  );

  Widget _buildSummarySection() => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        children: [
          const TextSpan(text: "총 공수 : "),
          TextSpan(
            text: "${_currentGongsu.toStringAsFixed(2)} 개",
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(text: "  |  총액(세전) : "),
          TextSpan(
            text: "${_formatCurrency(_currentPreTax)}원",
            style: const TextStyle(
              color: Color(0xFF2D6A4F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    ),
  );

  Widget _buildFourInsuranceGroup() {
    int t = _currentPreTax;
    int n = (t * (_getActiveRate("국민연금", isFourInsured) / 100)).toInt();
    int h = (t * (_getActiveRate("건강보험", isFourInsured) / 100)).toInt();
    int e = (t * (_getActiveRate("고용보험", isFourInsured) / 100)).toInt();
    int c = (h * (_getActiveRate("요양보험", isFourInsured) / 100)).toInt();

    int totalAmount = n + h + e + c;
    double totalPercent = t > 0 ? (totalAmount / t) * 100 : 0.0;

    return Column(
      children: [
        _buildGroupHeader(
          "4대보험",
          isFourInsured,
          (val) => _onGroupToggle('four', val!),
          showHelp: showFourHelp,
          onHelpToggle: () => setState(() => showFourHelp = !showFourHelp),
        ),
        _buildRateInputRow("국민연금", isFourInsured, n),
        _buildRateInputRow("건강보험", isFourInsured, h),
        _buildRateInputRow("고용보험", isFourInsured, e),
        _buildRateInputRow("요양보험", isFourInsured, c),
        _buildSubTotal("4대보험 합계", totalPercent, totalAmount),
      ],
    );
  }

  Widget _buildTaxGroup() {
    int t = _currentPreTax;
    int i = (t * (_getActiveRate("근로소득", isTax33) / 100)).toInt();
    int l = (t * (_getActiveRate("지방소득", isTax33) / 100)).toInt();
    int totalTaxAmount = i + l;
    double totalTaxPercent = t > 0 ? (totalTaxAmount / t) * 100 : 0.0;

    return Column(
      children: [
        _buildGroupHeader(
          "원천징수",
          isTax33,
          (val) => _onGroupToggle('tax', val!),
          showHelp: showTaxHelp,
          onHelpToggle: () => setState(() => showTaxHelp = !showTaxHelp),
        ),
        _buildRateInputRow("근로소득", isTax33, i),
        _buildRateInputRow("지방소득", isTax33, l),
        _buildSubTotal("원천징수 합계", totalTaxPercent, totalTaxAmount),
      ],
    );
  }

  Widget _buildUnionGroup() {
    int t = _currentPreTax;
    int u = (t * (_getActiveRate("노조비", isUnionMember) / 100)).toInt();

    return Column(
      children: [
        _buildGroupHeader(
          "노조비 적용",
          isUnionMember,
          (val) => _onGroupToggle('union', val!),
          showHelp: showUnionHelp,
          onHelpToggle: () => setState(() => showUnionHelp = !showUnionHelp),
        ),
        _buildRateInputRow("노조비", isUnionMember, u),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildNetPaySection() {
    int t = _currentPreTax;
    int n = (t * (_getActiveRate("국민연금", isFourInsured) / 100)).toInt();
    int h = (t * (_getActiveRate("건강보험", isFourInsured) / 100)).toInt();
    int e = (t * (_getActiveRate("고용보험", isFourInsured) / 100)).toInt();
    int c = (h * (_getActiveRate("요양보험", isFourInsured) / 100)).toInt();
    int fourTotal = n + h + e + c;

    int i = (t * (_getActiveRate("근로소득", isTax33) / 100)).toInt();
    int l = (t * (_getActiveRate("지방소득", isTax33) / 100)).toInt();
    int taxTotal = i + l;

    int u = (t * (_getActiveRate("노조비", isUnionMember) / 100)).toInt();

    int totalDeduction = fourTotal + taxTotal + u;
    int netPay = t - totalDeduction;
    double totalTaxPercent = t > 0 ? (totalDeduction / t) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "실수령액",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "${totalTaxPercent.toStringAsFixed(2)} %      ",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                TextSpan(
                  text: "${_formatCurrency(netPay)} 원",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: const Text(
      "* 기기에만 저장되며 설정하신 요율에 따른 추정치입니다.",
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey, fontSize: 11),
    ),
  );

  Widget _buildGroupHeader(
    String title,
    bool isChecked,
    ValueChanged<bool?> onChanged, {
    required bool showHelp,
    required VoidCallback onHelpToggle,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    color: Colors.grey.shade100,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onHelpToggle,
              child: const Icon(
                Icons.help_outline,
                size: 14,
                color: Colors.grey,
              ),
            ),
            if (showHelp) ...[
              const SizedBox(width: 4),
              const Text(
                "(체크:기본/해제:직접입력)",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
        Row(
          children: [
            Text(
              isChecked ? "체크" : "해제",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isChecked ? Colors.blue : Colors.grey,
              ),
            ),
            Checkbox(
              value: isChecked,
              onChanged: onChanged,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildRateInputRow(String label, bool isGroupChecked, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _controllers[label],
              readOnly: isGroupChecked,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixText: "%",
                hintText: defaultRates[label]!.toString(), // 비워졌을 때 보이는 힌트
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.right,
              onChanged: (v) {
                if (!isGroupChecked) {
                  _updateState(() => rates[label] = double.tryParse(v) ?? 0.0);
                }
              },
              style: TextStyle(
                color: isGroupChecked ? Colors.black87 : Colors.blue.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              "${_formatCurrency(amount)} 원",
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTotal(String label, double percent, int amount) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2D6A4F),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          "${percent.toStringAsFixed(2)} %   |   ${_formatCurrency(amount)} 원",
          style: const TextStyle(
            color: Color(0xFF2D6A4F),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}
