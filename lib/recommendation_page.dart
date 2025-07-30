import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.0.11:8000';

  static Future<List<String>> getRecommendations(
    List<Map<String, String>> scheduleData,
  ) async {
    final Uri url = Uri.parse('$baseUrl/recommendations');
    final response = await http.post(
      url,
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(scheduleData),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('recommendations')) {
        final List<dynamic> recList = decoded['recommendations'];
        return recList.map((e) => e.toString()).toList();
      } else {
        throw Exception('⚠️ 응답 형식이 올바르지 않습니다.');
      }
    } else {
      throw Exception('❌ 서버 오류: ${response.statusCode}');
    }
  }
}
