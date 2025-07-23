import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String _apiKey = 'AIzaSyAZ9a5gWaaHXDajx3ZBiN_i69Y0H6uTnwg';
  static const String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

  static Future<String> getRecommendation({
    required String currentWorkType,
    String? previousWorkType,
    String? nextWorkType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? bmiStatus = prefs.getString('profile_bmiStatus');

    String prompt =
        """
      당신은 교대근무자의 건강을 챙겨주는 다정하고 친절한 AI 건강 코치 '제미니'입니다.
      아래 주어진 사용자의 상황을 보고, 따뜻하고 부드러운 말투로 건강 팁을 추천해주세요.

      답변은 반드시 아래 형식을 완벽하게 지켜주세요.
      - 제목이나 인사말 없이, 가장 중요한 핵심 팁 3~4가지를 번호 목록으로만 바로 작성해주세요.
      - 각 팁은 "~해보세요", "~하는 건 어때요?" 와 같이 부드러운 권유형 문장으로 작성해주세요.
      - 각 팁 앞에 상황에 맞는 이모지를 1개씩 꼭 붙여주세요.

      [사용자 상황]
      - 어제 근무: ${previousWorkType ?? '정보 없음'}
      - **오늘 근무: $currentWorkType**
      - 내일 근무: ${nextWorkType ?? '정보 없음'}
    """;
    if (bmiStatus != null && bmiStatus.isNotEmpty) {
      prompt += "- 현재 BMI 상태: $bmiStatus\n";
    }

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final recommendation =
              data['candidates'][0]['content']['parts'][0]['text'];
          return recommendation.trim();
        }
        return _getFallbackRecommendation(
          currentWorkType,
          error: "AI의 답변이 비어있습니다.",
        );
      } else if (response.statusCode == 429) {
        return _getFallbackRecommendation(
          currentWorkType,
          error: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
        );
      } else {
        return _getFallbackRecommendation(
          currentWorkType,
          error: 'API 오류가 발생했습니다. (코드: ${response.statusCode})',
        );
      }
    } catch (e) {
      return _getFallbackRecommendation(
        currentWorkType,
        error: '인터넷 연결을 확인해주세요.',
      );
    }
  }

  static String _getFallbackRecommendation(String workType, {String? error}) {
    String message = error != null ? 'AI 추천을 가져오지 못했어요. ($error)\n\n' : '';
    switch (workType) {
      case '주간근무':
        return '${message}1. 😴 충분한 야간 수면으로 컨디션을 조절해보세요.\n2. 🥗 저녁은 소화가 잘되는 음식으로 챙겨드시는 건 어때요?\n3. 🚶‍♂️ 퇴근 후 가벼운 산책으로 하루를 마무리해보세요.';
      case '오후근무':
        return '${message}1. ☕ 근무 시작 전 가벼운 식사와 스트레칭은 필수예요!\n2. 💪 오전에 근력 운동으로 활력을 더해보세요.\n3. 💧 근무 중 물을 자주 마셔 수분을 보충해주세요.';
      case '야간근무':
        return '${message}1. ☀️ 근무 전 충분한 낮잠으로 피로를 미리 예방하세요.\n2. 🤸‍♂️ 근무 중 가벼운 스트레칭으로 몸을 풀어주는 건 어때요?\n3. 🍎 비타민이 풍부한 과일로 에너지를 보충해보세요.';
      default:
        return '${message}1. 😊 충분한 휴식을 취하며 재충전의 시간을 가져보세요.\n2. 🧘‍♂️ 명상이나 가벼운 요가로 마음을 챙겨보는 건 어때요?\n3. 📅 다음 근무를 위해 미리 계획을 세워보는 것도 좋아요.';
    }
  }
}
