import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BonusSettingDialog extends StatefulWidget {
  final int initialBasePay;
  final double initialWeeklyDays;
  final double initialMonthlyDays;
  final int initialEfficiency;
  final double initialTaxRate;

  const BonusSettingDialog({
    super.key,
    required this.initialBasePay,
    required this.initialWeeklyDays,
    required this.initialMonthlyDays,
    required this.initialEfficiency,
    required this.initialTaxRate,
  });

  @override
  State<BonusSettingDialog> createState() => _BonusSettingDialogState();
}

class _BonusSettingDialogState extends State<BonusSettingDialog> {
  late TextEditingController _basePayCtrl;
  late TextEditingController _weeklyCtrl;
  late TextEditingController _monthlyCtrl;
  late TextEditingController _efficiencyCtrl;
  late TextEditingController _taxRateCtrl;

  @override
  void initState() {
    super.initState();
    _basePayCtrl = TextEditingController(
      text: widget.initialBasePay == 0
          ? ''
          : _formatWithComma(widget.initialBasePay),
    );
    _weeklyCtrl = TextEditingController(
      text: widget.initialWeeklyDays == 0.0
          ? ''
          : widget.initialWeeklyDays.toStringAsFixed(2),
    );
    _monthlyCtrl = TextEditingController(
      text: widget.initialMonthlyDays == 0.0
          ? ''
          : widget.initialMonthlyDays.toStringAsFixed(2),
    );
    _efficiencyCtrl = TextEditingController(
      text: widget.initialEfficiency == 0
          ? ''
          : widget.initialEfficiency.toString(),
    );
    _taxRateCtrl = TextEditingController(
      text: widget.initialTaxRate == 0.0
          ? ''
          : widget.initialTaxRate.toString(),
    );
  }

  @override
  void dispose() {
    _basePayCtrl.dispose();
    _weeklyCtrl.dispose();
    _monthlyCtrl.dispose();
    _efficiencyCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        // ✅ 오버플로우 방지
        padding: MediaQuery.of(context).viewInsets,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "주차 / 월차 / 능률(보건) / 세율",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            _buildRow(
              label: "기준 단가",
              controller: _basePayCtrl,
              hint: widget.initialBasePay == 0
                  ? "금액"
                  : "${_formatWithComma(widget.initialBasePay)} 원", // ✅ 이전 금액 힌트로 표시
              unit: "원",
              inputType: TextInputType.number,
              formatters: [ThousandsSeparatorInputFormatter()],
            ),
            _buildRow(
              label: "주차",
              controller: _weeklyCtrl,
              hint: "4",
              unit: "개",
              inputType: const TextInputType.numberWithOptions(decimal: true),
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,0}')),
              ],
            ),
            _buildRow(
              label: "월차",
              controller: _monthlyCtrl,
              hint: "1",
              unit: "개",
              inputType: const TextInputType.numberWithOptions(decimal: true),
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
              ],
            ),
            _buildRow(
              label: "능률(보건)",
              controller: _efficiencyCtrl,
              hint: "2",
              unit: "개",
              inputType: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
            ),
            _buildRow(
              label: "소득세율",
              controller: _taxRateCtrl,
              hint: "3.3",
              unit: "%",
              inputType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey, // 취소는 눈에 덜 띄게 회색 처리
                  ),
                  child: const Text("취소"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'basePay':
                          int.tryParse(_basePayCtrl.text.replaceAll(',', '')) ??
                          0,
                      'weeklyDays': double.tryParse(_weeklyCtrl.text) ?? 0.0,
                      'monthlyDays': double.tryParse(_monthlyCtrl.text) ?? 0.0,
                      'efficiency': int.tryParse(_efficiencyCtrl.text) ?? 0,
                      'taxRate': double.tryParse(_taxRateCtrl.text) ?? 0.0,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                      255,
                      249,
                      217,
                      39,
                    ), // 정의된 노란색 사용
                    foregroundColor: Colors.black, // 노란 배경엔 검정 글자가 팩트
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text("저장"),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String unit,
    required TextInputType inputType,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: inputType,
              inputFormatters: formatters,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: hint,
                hintStyle: const TextStyle(
                  // ✅ 힌트색 연하게
                  color: Color.fromARGB(255, 218, 218, 218),
                  fontWeight: FontWeight.normal,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              unit,
              style: const TextStyle(
                color: Colors.black87, // ✅ 진하게
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWithComma(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

// ✅ 쉼표 입력 허용 Formatter (입력 시 자동 쉼표 포맷)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final nonDigit = RegExp(r'[^\d]');
    String digitsOnly = newValue.text.replaceAll(nonDigit, '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');

    final formatted = digitsOnly.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
