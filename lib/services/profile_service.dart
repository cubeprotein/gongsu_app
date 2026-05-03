import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // UID를 가져올 때 null 체크를 더 엄격히 수행
  String? get currentUid => _auth.currentUser?.uid;

  // [중요] 유저 데이터 실시간 감시 (이름 갱신 문제를 해결하는 핵심)
  Stream<UserModel?> get profileStream {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);

    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data()?['settings'] != null) {
        return UserModel.fromMap(
          Map<String, dynamic>.from(doc.data()!['settings']),
          uid,
        );
      }
      return UserModel(uid: uid);
    });
  }

  // 1. 유저 정보 저장
  Future<void> saveProfile(UserModel user) async {
    final uid = currentUid;
    if (uid == null) {
      print("프로필 저장 실패: 로그인 상태가 아닙니다.");
      return;
    }

    try {
      await _firestore.collection('users').doc(uid).set({
        'settings': user.toMap(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("프로필 저장 실패: $e");
      rethrow; // UI 단에서 에러를 인지할 수 있도록 전달
    }
  }

  // 2. 유저 정보 로드 (단발성)
  Future<UserModel> loadProfile() async {
    final uid = currentUid;
    if (uid == null) return UserModel();

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data()?['settings'] != null) {
        return UserModel.fromMap(
          Map<String, dynamic>.from(doc.data()!['settings']),
          uid,
        );
      }
    } catch (e) {
      print("프로필 로드 에러: $e");
    }
    return UserModel(uid: uid);
  }

  // 3. 로그아웃 (인증 해제)
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // 뇌피설 방지: 에러 발생 시 로그 확인용
      print("로그아웃 에러 발생: $e");
      rethrow;
    }
  }
}
