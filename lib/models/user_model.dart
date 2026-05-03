class UserModel {
  String uid;
  String name;
  String phoneNumber; // 추가
  String jobTitle;
  String siteName;
  String role;
  int defaultDayPay;

  UserModel({
    this.uid = "",
    this.name = "",
    this.phoneNumber = "",
    this.jobTitle = "",
    this.siteName = "",
    this.role = "",
    this.defaultDayPay = 0,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'phoneNumber': phoneNumber,
    'jobTitle': jobTitle,
    'siteName': siteName,
    'role': role,
    'defaultDayPay': defaultDayPay,
  };

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      name: map['name'] ?? "",
      phoneNumber: map['phoneNumber'] ?? "",
      jobTitle: map['jobTitle'] ?? "",
      siteName: map['siteName'] ?? "",
      role: map['role'] ?? "",
      defaultDayPay: map['defaultDayPay'] ?? 0,
    );
  }
}
