import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gongsu_app/holiday_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../../services/work_service.dart';
import 'daily_input_page.dart';
import 'work_calendar_bottom_summary.dart';
import 'work_calendar_drawer.dart';

const Color kAppBarColor = Color(0xFF3C486B);
const Color kBodyBackground = Color(0xFFF5F5F5);
const Color kCardColor = Colors.white;

class WorkCalendarPage extends StatefulWidget {
  final DateTime? initialDate;
  // [수정] 연간 통계에서 왔는지 확인하는 변수 추가
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
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  bool userIsPremium = false;
  final double _adjacentMonthOpacity = 0.3;
  final Map<String, Map<String, dynamic>> workData = {};
  Map<String, String> _koreanHolidays = {};
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _loadInitial();
    _loadPremiumFlag();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    final saved = await HolidayManager.getHolidays();
    if (mounted) setState(() => _koreanHolidays = saved);
    await HolidayManager.syncHolidays();
    final updated = await HolidayManager.getHolidays();
    if (mounted) setState(() => _koreanHolidays = updated);
  }

  Future<void> _loadInitial() async {
    final loaded = await WorkService.loadAllWorkData();
    final user = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() {
      workData.clear();
      workData.addAll(loaded);
      _currentUser = user;
    });
  }

  Future<void> _loadPremiumFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() => userIsPremium = prefs.getBool('isPremium') ?? false);
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
      onPopInvoked: (didPop) async {
        if (!didPop) await SystemNavigator.pop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: kBodyBackground,
        drawer: WorkCalendarDrawer(
          user: _currentUser,
          onProfileUpdate: _loadInitial,
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
                child: _buildCardBlock(
                  padding: EdgeInsets.zero,
                  useHorizontalMargin: false,
                  child: Column(
                    children: [
                      _buildCustomHeader(),
                      _buildWeekDaysRow(),
                      Expanded(child: _buildCalendarGrid(todayKey)),
                    ],
                  ),
                ),
              ),
              _buildCardBlock(
                useHorizontalMargin: false,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.22,
                  child: WorkCalendarBottomSummary(
                    workData: workData,
                    focusedMonth: _focusedDay,
                    isPremium: userIsPremium,
                  ),
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
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        useHorizontalMargin ? 12 : 3,
        0,
        useHorizontalMargin ? 12 : 3,
        10,
      ),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }

  // [수정된 헤더 함수]
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
            onPressed: () => setState(() {
              _focusedDay = DateTime(
                _focusedDay.year,
                _focusedDay.month - 1,
                1,
              );
              _selectedDay = null;
            }),
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
            onPressed: () => setState(() {
              _focusedDay = DateTime(
                _focusedDay.year,
                _focusedDay.month + 1,
                1,
              );
              _selectedDay = null;
            }),
          ),
          const Spacer(),

          // [수정 부분] 연간 통계에서 왔을 때만 우측에 닫기(X) 버튼 노출
          widget.fromYearly
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                )
              : const SizedBox(width: 48), // 평소에는 대칭을 위해 빈 공간 유지
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(String todayKey) {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    int emptyBefore = firstDay.weekday % 7;
    int weekCount = ((emptyBefore + lastDay.day) / 7).ceil();

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        setState(() {
          if ((details.primaryVelocity ?? 0) < 0) {
            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
          } else if ((details.primaryVelocity ?? 0) > 0) {
            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
          }
          _selectedDay = null;
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellHeight = constraints.maxHeight / weekCount;
          final cellWidth = constraints.maxWidth / 7;
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: cellWidth / cellHeight,
            ),
            itemCount: weekCount * 7,
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
              if (date.weekday % 7 == 6)
                dayColor = isAdj
                    ? Colors.blue.shade300
                    : const Color(0xFF002FFF);
              if (date.weekday % 7 == 0 || _koreanHolidays.containsKey(dateKey))
                dayColor = isAdj
                    ? Colors.red.shade300
                    : const Color(0xFFFF1100);

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
      ),
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
    final workDay = (data?['workDay'] ?? 0);
    final dayPay = _getDayPay(data) ?? 0;
    final siteName = (data?['siteName'] ?? '').toString();
    final leave = (data?['leave'] ?? 0).toInt();
    final bool hasMemo =
        data?['memo'] != null && data!['memo'].toString().trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final ch = constraints.maxHeight;
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
                WorkService.deleteWorkLog(dateKey);
              } else {
                final newData = {
                  'workDay': (result['workDay'] ?? 0).toDouble(),
                  'dayPay': result['dayPay'] ?? 0,
                  'siteName': result['siteName'] ?? '',
                  'memo': result['memo'] ?? '',
                  'adjustment': (result['adjustment'] ?? 0).toDouble(),
                  'leave': (result['leave'] ?? 0).toInt(),
                };
                workData[dateKey] = newData;
                WorkService.saveWorkLog(dateKey, newData);
              }
            });
          },
          child: Opacity(
            opacity: isAdjacentMonth ? _adjacentMonthOpacity : 1.0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? kAppBarColor.withOpacity(0.08)
                    : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? kAppBarColor
                      : (isToday ? Colors.red : Colors.grey.shade200),
                  width: (isToday || isSelected) ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (leave > 0)
                            _badge(
                              '휴무',
                              const Color(0xFF2D6A4F),
                              (ch * 0.18).clamp(9, 13),
                            )
                          else if (workDay != 0)
                            _badge(
                              workDay.toString(),
                              _colorForWorkDay(workDay),
                              (ch * 0.18).clamp(9, 13),
                            ),
                          if (workDay != 0 && leave == 0) ...[
                            if (workDay * dayPay > 0)
                              FittedBox(
                                child: Text(
                                  NumberFormat(
                                    '#,###',
                                  ).format(workDay * dayPay),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (siteName.isNotEmpty)
                              Text(
                                siteName.length > 4
                                    ? '${siteName.substring(0, 4)}..'
                                    : siteName,
                                style: TextStyle(
                                  fontSize: (ch * 0.11).clamp(8, 11),
                                  color: Colors.grey[700],
                                ),
                              ),
                          ] else if (_koreanHolidays.containsKey(dateKey) &&
                              workDay == 0)
                            FittedBox(
                              child: Text(
                                _koreanHolidays[dateKey]!,
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _badge(String text, Color color, double fontSize) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
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
