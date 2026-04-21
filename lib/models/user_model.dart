// lib/models/user_model.dart
class UserModel {
  String name;
  String jobTitle;
  String siteName;
  String role;

  UserModel({
    this.name = "홍길동",
    this.jobTitle = "배관기능장",
    this.siteName = "현장 미설정",
    this.role = "담당 업무 미설정",
  });

  // 저장용 (Map 변환)
  Map<String, dynamic> toMap() => {
    'name': name,
    'jobTitle': jobTitle,
    'siteName': siteName,
    'role': role,
  };

  // 불러오기용 (Factory 생성자)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? "홍길동",
      jobTitle: map['jobTitle'] ?? "배관기능장",
      siteName: map['siteName'] ?? "현장 미설정",
      role: map['role'] ?? "담당 업무 미설정",
    );
  }
}