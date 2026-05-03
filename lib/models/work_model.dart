class WorkModel {
  final String id; // 날짜 (예: 2026-04-21) - Firestore 문서 ID로 사용
  final double workDay; // 공수 (1.0, 0.5 등)
  final int dayPay; // 단가
  final String siteName; // 현장명
  final String memo; // 메모 (오늘 추가 사항)
  final double adjustment; // 조정 금액
  final int leave; // 휴무 여부 (1: 휴무, 0: 출근)

  WorkModel({
    required this.id,
    this.workDay = 0.0,
    this.dayPay = 0,
    this.siteName = '',
    this.memo = '',
    this.adjustment = 0.0,
    this.leave = 0,
  });

  // 1. JSON/Map 데이터를 객체로 변환 (불러오기용)
  factory WorkModel.fromMap(String id, Map<String, dynamic> map) {
    return WorkModel(
      id: id,
      workDay: (map['workDay'] ?? 0.0).toDouble(),
      dayPay: map['dayPay'] ?? 0,
      siteName: map['siteName'] ?? '',
      memo: map['memo'] ?? '',
      adjustment: (map['adjustment'] ?? 0.0).toDouble(),
      leave: map['leave'] ?? 0,
    );
  }

  // 2. 객체를 Map으로 변환 (저장용 - Firestore/SharedPrefs)
  Map<String, dynamic> toMap() {
    return {
      'workDay': workDay,
      'dayPay': dayPay,
      'siteName': siteName,
      'memo': memo,
      'adjustment': adjustment,
      'leave': leave,
    };
  }
}
