import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/work_service.dart';
import 'work_calendar_page.dart';

class YearStatisticsPage extends StatefulWidget {
  final int year;
  const YearStatisticsPage({super.key, required this.year});

  @override
  State<YearStatisticsPage> createState() => _YearStatisticsPageState();
}

class _YearStatisticsPageState extends State<YearStatisticsPage> {
  late int _currentYear;
  Map<String, Map<String, dynamic>> yearlyData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.year;
    _loadYearlyData();
  }

  // 데이터 로드 로직 (연도 변경이나 화면 복귀 시 호출)
  Future<void> _loadYearlyData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    final data = await WorkService.getYearlyData(_currentYear);
    if (mounted) {
      setState(() {
        yearlyData = data;
        isLoading = false;
      });
    }
  }

  void _showYearPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '연도 선택',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 11,
            itemBuilder: (context, index) {
              int year = DateTime.now().year - 5 + index;
              return ListTile(
                title: Text('$year년', textAlign: TextAlign.center),
                selected: year == _currentYear,
                onTap: () {
                  setState(() => _currentYear = year);
                  _loadYearlyData();
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 실시간 연간 합계 계산 (화면이 그려질 때마다 최신 yearlyData 반영)
    double totalYearlyWorkDay = 0;
    double totalYearlyAmount = 0;

    yearlyData.forEach((key, value) {
      final double workDay =
          double.tryParse(value['workDay']?.toString() ?? '0') ?? 0.0;
      final num dayPay = num.tryParse(value['dayPay']?.toString() ?? '0') ?? 0;
      totalYearlyWorkDay += workDay;
      totalYearlyAmount += (workDay * dayPay);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('연간 공수 현황'),
        backgroundColor: const Color(0xFF3C486B),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 45,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildYearHeader(),
            _buildYearlySummary(totalYearlyWorkDay, totalYearlyAmount),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.72,
                            children: List.generate(
                              12,
                              (index) => _buildMonthItem(index + 1),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 1단: 연도 선택 조절바 (패딩 최소화)
  Widget _buildYearHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: const Icon(
              Icons.arrow_left,
              size: 30,
              color: Color(0xFF3C486B),
            ),
            onPressed: () {
              setState(() => _currentYear--);
              _loadYearlyData();
            },
          ),
          GestureDetector(
            onTap: _showYearPicker,
            child: Text(
              '$_currentYear년',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C486B),
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: const Icon(
              Icons.arrow_right,
              size: 30,
              color: Color(0xFF3C486B),
            ),
            onPressed: () {
              setState(() => _currentYear++);
              _loadYearlyData();
            },
          ),
        ],
      ),
    );
  }

  // 2단: 연간 요약 바 (글자 시인성 강화)
  Widget _buildYearlySummary(double totalGongsu, double totalAmount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3C486B).withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _summaryItem("총 공수", totalGongsu.toStringAsFixed(1))),
          Container(width: 1, height: 12, color: Colors.grey.shade400),
          Expanded(
            child: _summaryItem(
              "총 금액",
              NumberFormat('#,###').format(totalAmount),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "$label : ",
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF444444),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF000000),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthItem(int month) {
    double monthlyTotal = 0;
    yearlyData.forEach((key, value) {
      if (key.startsWith('$_currentYear-${month.toString().padLeft(2, '0')}')) {
        final double workDay =
            double.tryParse(value['workDay']?.toString() ?? '0') ?? 0.0;
        final num dayPay =
            num.tryParse(value['dayPay']?.toString() ?? '0') ?? 0;
        monthlyTotal += (workDay * dayPay);
      }
    });

    return GestureDetector(
      // [핵심 수정] async/await를 사용하여 월간 달력에서 돌아올 때 데이터를 새로고침함
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkCalendarPage(
              initialDate: DateTime(_currentYear, month, 1),
              fromYearly: true,
            ),
          ),
        );
        _loadYearlyData(); // 돌아오는 순간 DB에서 최신 데이터 다시 로드
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '$month월',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(child: _buildMiniCalendar(month)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${NumberFormat('#,###').format(monthlyTotal)}원',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCalendar(int month) {
    final firstDay = DateTime(_currentYear, month, 1);
    final lastDay = DateTime(_currentYear, month + 1, 0);
    final startWeekday = firstDay.weekday % 7;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 1.2,
        crossAxisSpacing: 1.2,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final dayNum = index - startWeekday + 1;
        if (dayNum <= 0 || dayNum > lastDay.day) return const SizedBox();

        final dateKey = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(_currentYear, month, dayNum));
        final data = yearlyData[dateKey];

        // 공수와 휴무 데이터를 함께 체크
        final workDay =
            double.tryParse(data?['workDay']?.toString() ?? '0') ?? 0.0;
        final int leave = int.tryParse(data?['leave']?.toString() ?? '0') ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: _getHeatmapColor(workDay, leave),
            borderRadius: BorderRadius.circular(1),
          ),
          child: Center(
            child: Text(
              '$dayNum',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 5.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // 색상 로직 (휴무 진녹색 추가)
  Color _getHeatmapColor(double wd, int leave) {
    if (leave > 0) return const Color(0xFF2D6A4F); // 휴무 (진녹색)
    if (wd == 0) return Colors.grey.shade300; // 일 없음 (회색)
    if (wd <= 0.5) return const Color(0xFFFBC02D); // 0.5공수 (노랑)
    if (wd == 1.0) return const Color(0xFF617A98); // 1.0공수 (파랑)
    if (wd >= 2.0) return const Color(0xFFE54E4B); // 2.0이상 (빨강)
    return const Color(0xFF617A98);
  }
}
