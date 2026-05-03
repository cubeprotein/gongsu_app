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
    // ✅ Firestore에서 넘어온 초기값으로만 설정 (SharedPreferences 삭제)
    _basePayCtrl = TextEditingController(
      text: widget.initialBasePay == 0
          ? ''
          : _formatWithComma(widget.initialBasePay),
    );
    _weeklyCtrl = TextEditingController(
      text: widget.initialWeeklyDays == 0.0
          ? ''
          : widget.initialWeeklyDays.toString(),
    );
    _monthlyCtrl = TextEditingController(
      text: widget.initialMonthlyDays == 0.0
          ? ''
          : widget.initialMonthlyDays.toString(),
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
              hint: "금액",
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
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            _buildRow(
              label: "월차",
              controller: _monthlyCtrl,
              hint: "1",
              unit: "개",
              inputType: const TextInputType.numberWithOptions(decimal: true),
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            _buildRow(
              label: "능률(보건)",
              controller: _efficiencyCtrl,
              hint: "1",
              unit: "개",
              inputType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            _buildRow(
              label: "소득세율",
              controller: _taxRateCtrl,
              hint: "직접입력  예) 3.3",
              unit: "%",
              inputType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("취소", style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // ✅ 저장 버튼 클릭 시 결과만 반환 (저장 처리는 부모 위젯에서 Firestore로 수행)
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
                    backgroundColor: const Color(0xFFF9D949),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    "저장",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 8),
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
                  color: Color.fromARGB(163, 198, 198, 198),
                  fontSize: 14,
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
              style: const TextStyle(fontWeight: FontWeight.bold),
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

// 콤마 포맷터 클래스는 동일하게 유지
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
