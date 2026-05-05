import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../../services/work_service.dart';
import 'work_calendar_page.dart';
import '../tax/export_report_modal.dart';

class YearStatisticsPage extends StatefulWidget {
  final int year;
  const YearStatisticsPage({super.key, required this.year});

  @override
  State<YearStatisticsPage> createState() => _YearStatisticsPageState();
}

class _YearStatisticsPageState extends State<YearStatisticsPage> {
  final GlobalKey _repaintKey = GlobalKey();
  late int _currentYear;
  final _workService = WorkService();

  Map<String, Map<String, dynamic>> yearlyData = {};
  Map<int, Map<String, dynamic>> monthlyCalculated = {};
  double totalYearGongsu = 0;
  double totalYearAmount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.year;
    _loadYearlyData();
  }

  Future<void> _loadYearlyData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final List<Map<String, dynamic>> allMonthsRaw = await Future.wait(
        List.generate(
          12,
          (i) => _workService.getMonthlyData(_currentYear, i + 1),
        ),
      );

      Map<String, Map<String, dynamic>> tempYearlyData = {};
      Map<int, Map<String, dynamic>> tempCalculated = {};
      double tempTotalGongsu = 0;
      double tempTotalAmount = 0;

      for (int i = 0; i < 12; i++) {
        final month = i + 1;
        final rawData = allMonthsRaw[i];

        final summary = _workService.calculateMonthSummaryFromMap(rawData);
        tempCalculated[month] = summary;

        tempTotalGongsu += (summary['totalGongsu'] ?? 0).toDouble();
        tempTotalAmount += (summary['totalAmount'] ?? 0).toDouble();

        rawData.forEach((dayKey, value) {
          if (dayKey == 'bonus_config') return;
          String fullDateKey =
              "$_currentYear-${month.toString().padLeft(2, '0')}-${dayKey.padLeft(2, '0')}";
          tempYearlyData[fullDateKey] = Map<String, dynamic>.from(value as Map);
        });
      }

      if (mounted) {
        setState(() {
          yearlyData = tempYearlyData;
          monthlyCalculated = tempCalculated;
          totalYearGongsu = tempTotalGongsu;
          totalYearAmount = tempTotalAmount;
        });
      }
    } catch (e) {
      debugPrint("년간 데이터 로드 에러: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
          child: ExportReportModal(title: "연간 공수표", capturedImage: pngBytes),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('연간 공수 현황'),
        backgroundColor: const Color(0xFF3C486B),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 45,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white),
            onPressed: _showExport,
          ),
        ],
      ),
      body: SafeArea(
        bottom: true, // 하단 네비게이션 바 침범 방지
        child: RepaintBoundary(
          key: _repaintKey,
          child: Container(
            color: const Color(0xFFF5F5F5),
            child: Column(
              children: [
                _buildYearHeader(),
                _buildYearlySummary(totalYearGongsu, totalYearAmount),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3C486B),
                          ),
                        )
                      // ✅ LayoutBuilder 적용: 기기별 남은 세로 공간 계산 및 동적 비율 적용
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            const double padding = 10.0;
                            const double crossSpacing = 8.0;
                            const double mainSpacing = 8.0;

                            final double availableWidth =
                                constraints.maxWidth - (padding * 2);
                            final double availableHeight =
                                constraints.maxHeight - (padding * 2);

                            final double itemWidth =
                                (availableWidth - (crossSpacing * 2)) / 3;
                            final double itemHeight =
                                (availableHeight - (mainSpacing * 3)) / 4;

                            final double dynamicRatio = itemWidth / itemHeight;

                            return Padding(
                              padding: const EdgeInsets.all(padding),
                              child: GridView.builder(
                                physics:
                                    const NeverScrollableScrollPhysics(), // 스크롤 방지
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: crossSpacing,
                                      mainAxisSpacing: mainSpacing,
                                      childAspectRatio:
                                          dynamicRatio, // 동적 비율 적용
                                    ),
                                itemCount: 12,
                                itemBuilder: (context, index) =>
                                    _buildMonthItem(index + 1),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
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
          Text(
            '$_currentYear년',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C486B),
            ),
          ),
          IconButton(
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

  Widget _buildYearlySummary(double gongsu, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3C486B).withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "총 공수 : ${gongsu.toStringAsFixed(1)}",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 20),
          Text(
            "총 금액(세전) : ${NumberFormat('#,###').format(amount)}원",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthItem(int month) {
    final summary =
        monthlyCalculated[month] ?? {'totalGongsu': 0.0, 'totalAmount': 0.0};
    final double gongsu = summary['totalGongsu'];
    final double amount = summary['totalAmount'];

    return GestureDetector(
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
        _loadYearlyData();
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
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Center(
                // ✅ FittedBox 적용
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${gongsu.toStringAsFixed(1)} / ${NumberFormat('#,###').format(amount)}원',
                    style: const TextStyle(
                      fontSize: 10,
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

        final bool isPaidLeave = data?['isPaidLeave'] == true;

        return Container(
          decoration: BoxDecoration(
            color: _getHeatmapColor(
              double.tryParse(data?['workDay']?.toString() ?? '0') ?? 0.0,
              int.tryParse(data?['leave']?.toString() ?? '0') ?? 0,
              isPaidLeave,
            ),
            borderRadius: BorderRadius.circular(1),
          ),
          child: Center(
            // ✅ FittedBox 적용: 고정 폰트 크기(5.5) 제거
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(0.5),
                child: Text(
                  '$dayNum',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7, // 약간 키워두고 자동 축소되게 함
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getHeatmapColor(double wd, int leave, bool isPaidLeave) {
    if (isPaidLeave) return const Color(0xFF8E44AD);
    if (leave > 0) return const Color(0xFF2D6A4F);
    if (wd == 0) return Colors.grey.shade300;
    if (wd <= 0.5) return const Color(0xFFFBC02D);
    if (wd == 1.0) return const Color(0xFF617A98);
    if (wd > 1.0 && wd < 2.0) return const Color(0xFF2C2C2C);
    return const Color(0xFFE54E4B);
  }
}
