const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

// 2세대(v2) 규격의 카카오 인증 함수
exports.kakaoCustomAuth = onCall({
    region: "us-central1" // 에러가 났던 그 지역 그대로 설정
}, async (request) => {
    // 2세대에서는 데이터가 request.data에 담겨 옵니다.
    const accessToken = request.data.accessToken;

    if (!accessToken) {
        throw new HttpsError("invalid-argument", "카카오 액세스 토큰이 없습니다.");
    }

    try {
        // 1. 카카오 서버에 사용자 정보 확인
        const response = await axios.get("https://kapi.kakao.com/v2/user/me", {
            headers: { Authorization: `Bearer ${accessToken}` }
        });

        const kakaoUser = response.data;
        const uid = `kakao:${kakaoUser.id}`;

        // 2. 파이어베이스 커스텀 토큰 생성
        const customToken = await admin.auth().createCustomToken(uid, {
            displayName: kakaoUser.properties.nickname || "카카오 유저",
            photoURL: kakaoUser.properties.profile_image || ""
        });

        return { token: customToken };
    } catch (error) {
        console.error("카카오 인증 에러:", error);
        throw new HttpsError("internal", error.message);
    }
});