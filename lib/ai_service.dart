import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String _apiKey = 'AIzaSyAZ9a5gWaaHXDajx3ZBiN_i69Y0H6uTnwg';
  static const String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

  static Future<String> getSimpleHealthTip({
    required String currentWorkType,
  }) async {
    String prompt = """
      당신은 교대근무자의 건강을 챙겨주는 AI 건강 코치입니다.
      주어진 사용자의 오늘 근무 형태를 보고, 가장 중요한 핵심 건강 팁 딱 한 가지만을 50자 이내의 짧고 간결한 문장으로 추천해주세요.
      다른 인사, 제목, 번호, 이모지 없이 오직 팁 문장 하나만 "오늘은 ~로 컨디션을 조절해보세요." 와 같은 부드러운 권유형으로 작성해주세요.
      [사용자 상황]
      - **오늘 근무: $currentWorkType**
    """;
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'safetySettings': _safetySettings,
        }),
      );
      if (response.statusCode == 200) {
        return _parseResponse(response);
      }
      return "오류가 발생했습니다. (코드: ${response.statusCode})";
    } catch (e) {
      return "인터넷 연결을 확인해주세요.";
    }
  }

  static Future<String> getDetailedRecommendation({
    required String currentWorkType,
    String? previousWorkType,
    String? nextWorkType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? bmiStatus = prefs.getString('profile_bmiStatus');
    String prompt = """
      당신은 교대근무자의 하루를 완벽하게 설계해주는 전문 라이프 코치 AI입니다.
      주어진 사용자의 근무 및 건강 상태를 면밀히 분석하여, 전반적인 생활 패턴에 대한 추천 리스트를 작성해주세요.
      - 분석 내용을 바탕으로 식사, 운동, 수면(낮잠) 등 가장 중요한 3~4가지 항목을 추천해주세요.
      - 각 항목은 번호 목록(1., 2., 3.)으로, 관련된 이모지와 함께 굵은 글씨로 주제를 표시해주세요. (예: **🍽️ 식사 시간:**)
      - 각 주제 뒤에는 구체적인 시간과 이유를 포함한 상세한 추천 내용을 1~2 문장으로 작성해주세요.
      [사용자 상황]
      - 어제 근무: ${previousWorkType ?? '정보 없음'}
      - **오늘 근무: $currentWorkType**
      - 내일 근무: ${nextWorkType ?? '정보 없음'}
      - 현재 BMI 상태: ${bmiStatus ?? '정보 없음'}
    """;
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'safetySettings': _safetySettings,
        }),
      );
      if (response.statusCode == 200) {
        return _parseResponse(response);
      }
      return "상세 추천을 불러오는 데 실패했습니다.";
    } catch (e) {
      return "인터넷 연결을 확인해주세요.";
    }
  }

  // ✅ [요청사항] 운동 추천 함수에 근무 스케줄 정보를 추가로 받도록 수정
  static Future<String> getWorkoutRecommendation({
    required String currentWorkType,
    String? previousWorkType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? bmiStatus = prefs.getString('profile_bmiStatus');
    if (bmiStatus == null || bmiStatus.isEmpty) {
      return '프로필에서 BMI를 먼저 계산해주세요!\n\n나에게 맞는 운동을 추천해 드릴게요. 💪';
    }

    // ✅ 근무 스케줄까지 고려하도록 프롬프트 강화
    String prompt = """
      당신은 전문 AI 피트니스 코치입니다. 주어진 BMI 상태와 근무 스케줄을 종합적으로 분석하여 맞춤 운동을 추천해주세요.
      예를 들어, 야간 근무 다음 날에는 회복을 위한 가벼운 유산소를, 휴일에는 강도 있는 근력 운동을 추천할 수 있습니다.
      답변은 아래 형식을 반드시 지켜주세요.
      - 첫 줄에는 추천 운동 종류에 맞는 제목 작성 (예: 🏃‍♂️ 오늘의 유산소 운동 추천)
      - 다음 줄에는 동기 부여 문장 한 줄 작성.
      - 그 아래에는 추천 운동 2~3가지를 번호 목록으로 작성.
      - 각 운동 이름은 굵은 글씨(**)로, 옆에 간단한 설명 1~2문장 덧붙이기.
      [사용자 데이터]
      - BMI 상태: $bmiStatus
      - 어제 근무: ${previousWorkType ?? '정보 없음'}
      - **오늘 근무: $currentWorkType**
    """;
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'safetySettings': _safetySettings,
        }),
      );
      if (response.statusCode == 200) {
        return _parseResponse(response);
      }
      return 'AI 운동 추천에 오류가 발생했습니다.';
    } catch (e) {
      return '인터넷 연결을 확인 후 다시 시도해주세요.';
    }
  }

  static Future<String> getQuoteOfTheDay() async {
    String prompt = """
      사용자에게 동기부여가 될 만한 짧고 힘이 되는 명언을 딱 하나만 추천해줘.
      다른 설명이나 인사 없이, "명언 내용" - 출처 형식으로만 답변해줘.
    """;
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'safetySettings': _safetySettings,
        }),
      );
      if (response.statusCode == 200) {
        return _parseResponse(response);
      }
      return '"가장 큰 영광은 한 번도 실패하지 않음이 아니라 실패할 때마다 다시 일어서는 데에 있다." - 공자';
    } catch (e) {
      return '"천리길도 한 걸음부터." - 노자';
    }
  }

  static final _safetySettings = [
    {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
    {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
    {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
    {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
  ];

  static String _parseResponse(http.Response response) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data['candidates'] != null && data['candidates'].isNotEmpty) {
      return data['candidates'][0]['content']['parts'][0]['text'].trim();
    }
    return "AI가 응답하지 않습니다. 잠시 후 시도해주세요.";
  }
}
