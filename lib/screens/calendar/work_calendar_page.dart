import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../holiday_manager.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../../services/work_service.dart';
import '../tax/export_report_modal.dart';
import 'daily_input_page.dart';
import 'work_calendar_bottom_summary.dart';
import 'work_calendar_drawer.dart';

const Color kAppBarColor = Color(0xFF3C486B);
const Color kBodyBackground = Color(0xFFF5F5F5);
const Color kCardColor = Colors.white;

class WorkCalendarPage extends StatefulWidget {
  final DateTime? initialDate;
  final bool fromYearly;
  const WorkCalendarPage({
    super.key,
    this.initialDate,
    this.fromYearly = false,
  });

  @override
  State<WorkCalendarPage> createState() => _WorkCalendarPageState();
}

class _WorkCalendarPageState extends State<WorkCalendarPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _repaintKey = GlobalKey();

  final _workService = WorkService();
  final _profileService = ProfileService();

  late DateTime _focusedDay;
  DateTime? _selectedDay;
  bool userIsPremium = false;
  final double _adjacentMonthOpacity = 0.3;

  Map<String, Map<String, dynamic>> workData = {};
  Map<String, String> _koreanHolidays = {};
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _loadInitialData();
    _loadPremiumFlag();
  }

  Future<void> _loadPremiumFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => userIsPremium = prefs.getBool('isPremium') ?? false);
    }
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      _workService.getMonthlyDataForUI(_focusedDay.year, _focusedDay.month),
      _profileService.loadProfile(),
      HolidayManager.getHolidays(),
    ]);
    if (!mounted) return;
    setState(() {
      workData = Map<String, Map<String, dynamic>>.from(
        results[0] as Map<String, Map<String, dynamic>>,
      );
      _currentUser = results[1] as UserModel;
      _koreanHolidays = results[2] as Map<String, String>;
    });
  }

  double _calculateTotalGongsu() {
    double total = 0;
    workData.forEach((key, value) {
      total += (value['workDay'] ?? 0);
      if (value['isPaidLeave'] == true) total += 1.0;
    });
    return total;
  }

  int _calculateTotalPay() {
    double total = 0;
    workData.forEach((key, value) {
      double wd = (value['workDay'] ?? 0).toDouble();
      if (value['isPaidLeave'] == true) wd += 1.0;
      double dp = (value['dayPay'] ?? value['unitPrice'] ?? 0).toDouble();
      total += (wd * dp);
    });
    return total.toInt();
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
          child: ExportReportModal(title: "월간 공수표", capturedImage: pngBytes),
        );
      },
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + offset, 1);
      _selectedDay = null;
    });
    _loadInitialData();
  }

  num? _getDayPay(Map<String, dynamic>? data) {
    if (data == null) return null;
    final v = data['dayPay'] ?? data['unitPrice'];
    return v is num ? v : num.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await SystemNavigator.pop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: kBodyBackground,
        drawer: WorkCalendarDrawer(
          user: _currentUser,
          onProfileUpdate: _loadInitialData,
          totalGongsu: _calculateTotalGongsu(),
          totalPreTax: _calculateTotalPay(),
          focusedMonth: _focusedDay,
        ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: AppBar(
            elevation: 0,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: kAppBarColor,
              statusBarIconBrightness: Brightness.light,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _buildCardBlock(
                    padding: EdgeInsets.zero,
                    useHorizontalMargin: false,
                    customBorderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                      bottom: Radius.zero,
                    ),
                    child: Column(
                      children: [
                        _buildCustomHeader(),
                        _buildWeekDaysRow(),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            // 상하 스와이프 이벤트 흡수(차단)
                            onVerticalDragStart: (_) {},
                            onVerticalDragUpdate: (_) {},
                            onVerticalDragEnd: (_) {},
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity == null) return;
                              if (details.primaryVelocity! < -300) {
                                _changeMonth(1);
                              } else if (details.primaryVelocity! > 300) {
                                _changeMonth(-1);
                              }
                            },
                            child: _buildCalendarGrid(todayKey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildCardBlock(
                useHorizontalMargin: false,
                child: WorkCalendarBottomSummary(
                  workData: workData,
                  focusedMonth: _focusedDay,
                  isPremium: userIsPremium,
                  onRefresh: _loadInitialData,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBlock({
    required Widget child,
    EdgeInsets? padding,
    bool useHorizontalMargin = true,
    BorderRadius? customBorderRadius,
  }) {
    final radius = customBorderRadius ?? BorderRadius.circular(12);
    return Container(
      margin: EdgeInsets.fromLTRB(
        useHorizontalMargin ? 12 : 3,
        0,
        useHorizontalMargin ? 12 : 3,
        10,
      ),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      color: kAppBarColor,
      height: 44,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            '${_focusedDay.year}년 ${_focusedDay.month}월',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => _changeMonth(1),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white, size: 22),
            onPressed: _showExport,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(String todayKey) {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    int emptyBefore = firstDay.weekday % 7;
    int totalCells = ((emptyBefore + lastDay.day) / 7).ceil() * 7;
    int weekCount = totalCells ~/ 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellHeight = constraints.maxHeight / weekCount;
        final cellWidth = constraints.maxWidth / 7;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: cellWidth / cellHeight,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            int dayNum = index - emptyBefore + 1;
            bool isAdj = dayNum <= 0 || dayNum > lastDay.day;
            DateTime date = isAdj
                ? (dayNum <= 0
                      ? firstDay.subtract(Duration(days: emptyBefore - index))
                      : lastDay.add(Duration(days: dayNum - lastDay.day)))
                : DateTime(_focusedDay.year, _focusedDay.month, dayNum);

            final dateKey = DateFormat('yyyy-MM-dd').format(date);
            Color dayColor = isAdj
                ? Colors.grey.shade400
                : const Color(0xFF2C2C2C);
            if (date.weekday % 7 == 6) {
              dayColor = isAdj ? Colors.blue.shade300 : const Color(0xFF002FFF);
            }
            if (date.weekday % 7 == 0 || _koreanHolidays.containsKey(dateKey)) {
              dayColor = isAdj ? Colors.red.shade300 : const Color(0xFFFF1100);
            }

            return _buildIldaoCell(
              date: date,
              dayTextColor: dayColor,
              data: workData[dateKey],
              isToday: dateKey == todayKey,
              isAdjacentMonth: isAdj,
            );
          },
        );
      },
    );
  }

  Widget _buildIldaoCell({
    required DateTime date,
    required Color dayTextColor,
    required Map<String, dynamic>? data,
    required bool isToday,
    required bool isAdjacentMonth,
  }) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final isSelected =
        _selectedDay != null &&
        DateFormat('yyyy-MM-dd').format(_selectedDay!) == dateKey;
    final holidayName = _koreanHolidays[dateKey];
    final workDay = (data?['workDay'] ?? 0);
    final dayPay = _getDayPay(data) ?? 0;
    final siteName = (data?['siteName'] ?? '').toString();
    final leave = (data?['leave'] ?? 0).toInt();
    final isPaidLeave = data?['isPaidLeave'] == true;
    final bool hasMemo =
        data?['memo'] != null && data!['memo'].toString().trim().isNotEmpty;

    return GestureDetector(
      onTap: () async {
        setState(() => _selectedDay = date);
        final result = await Navigator.push<Map<String, dynamic>?>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DailyInputPage(selectedDate: date, initialData: data),
          ),
        );
        if (result == null) return;
        setState(() {
          if (result['__delete__'] == true) {
            workData.remove(dateKey);
            _workService.deleteWorkLog(dateKey);
          } else {
            final newData = {
              'workDay': (result['workDay'] ?? 0).toDouble(),
              'dayPay': result['dayPay'] ?? 0,
              'siteName': result['siteName'] ?? '',
              'memo': result['memo'] ?? '',
              'adjustment': (result['adjustment'] ?? 0).toDouble(),
              'leave': (result['leave'] ?? 0).toInt(),
              'isPaidLeave': result['isPaidLeave'] ?? false,
            };
            workData[dateKey] = newData;
            _workService.saveWorkLog(dateKey, newData);
          }
        });
      },
      child: Opacity(
        opacity: isAdjacentMonth ? _adjacentMonthOpacity : 1.0,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? kAppBarColor.withOpacity(0.08) : Colors.white,
            border: Border.all(
              color: isSelected
                  ? kAppBarColor
                  : (isToday ? Colors.red : Colors.grey.shade200),
              width: (isToday || isSelected) ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? kAppBarColor : dayTextColor,
                    ),
                  ),
                  if (hasMemo)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 1),
                    if (isPaidLeave)
                      _badge('유급', Colors.orange, 8.5)
                    else if (leave > 0)
                      _badge('휴무', const Color(0xFF2D6A4F), 8.5)
                    else if (workDay != 0)
                      _badge(
                        workDay.toString(),
                        _colorForWorkDay(workDay),
                        8.0,
                      ),
                    if (!isAdjacentMonth &&
                        holidayName != null &&
                        workDay == 0 &&
                        leave == 0 &&
                        !isPaidLeave)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            holidayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 8.0,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    if (workDay != 0 && leave == 0 && !isPaidLeave) ...[
                      const SizedBox(height: 3),
                      if (workDay * dayPay > 0)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            NumberFormat('#,###').format(workDay * dayPay),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      const SizedBox(height: 1.8),
                      if (siteName.isNotEmpty)
                        Text(
                          siteName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[900],
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, double fontSize) {
    return Container(
      width: 35,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }

  Color _colorForWorkDay(dynamic wd) {
    if (wd is! num) return const Color(0xFF3D3D3D);
    if (wd <= 0.5) return const Color(0xFFFBC02D);
    if (wd == 1) return const Color(0xFF617A98);
    if (wd >= 2) return const Color(0xFFE54E4B);
    return const Color(0xFF3D3D3D);
  }

  Widget _buildWeekDaysRow() {
    const days = ['일', '월', '화', '수', '목', '금', '토'];
    return Container(
      color: kAppBarColor,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: days.map((d) {
          Color c = Colors.white;
          if (d == '토') c = const Color(0xFF767DFF);
          if (d == '일') c = const Color(0xFFFF7171);
          return Expanded(
            child: Center(
              child: Text(
                d,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: c,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
