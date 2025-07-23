import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String bmiResult = '';
  String bmiStatus = '';
  List<String> bmiRecommendations = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// ✅ 저장된 값 불러오기
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? '';
      _ageController.text = prefs.getString('profile_age') ?? '';
      _heightController.text = prefs.getString('profile_height') ?? '';
      _weightController.text = prefs.getString('profile_weight') ?? '';
      bmiResult = prefs.getString('profile_bmiResult') ?? '';
      bmiStatus = prefs.getString('profile_bmiStatus') ?? '';
      bmiRecommendations =
          prefs.getStringList('profile_bmiRecommendations') ?? [];
    });
  }

  /// ✅ 값 저장하기
  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text);
    await prefs.setString('profile_age', _ageController.text);
    await prefs.setString('profile_height', _heightController.text);
    await prefs.setString('profile_weight', _weightController.text);
    await prefs.setString('profile_bmiResult', bmiResult);
    await prefs.setString('profile_bmiStatus', bmiStatus);
    await prefs.setStringList('profile_bmiRecommendations', bmiRecommendations);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ 프로필이 저장되었습니다.')));
  }

  /// ✅ BMI 계산
  void _calculateBMI() {
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    if (height != null && weight != null && height > 0) {
      final double bmi = weight / ((height / 100) * (height / 100));

      String status;
      List<String> recommendations = [];

      if (bmi < 18.5) {
        status = '저체중 (체중 증가 필요)';
        recommendations = [
          '🍗 단백질 섭취량 늘리기',
          '🏋️‍♂️ 근력운동으로 근육량 늘리기',
          '🍚 고칼로리 식단 유지하기',
        ];
      } else if (bmi < 23) {
        status = '정상 (적정 체중)';
        recommendations = [
          '✅ 현재 식단과 운동 유지',
          '🚶‍♂️ 가벼운 유산소 운동 추가',
          '🧘 스트레칭, 요가 병행',
        ];
      } else if (bmi < 25) {
        status = '과체중 (조금 조절 필요)';
        recommendations = [
          '🏃‍♂️ 유산소 운동 주 3회 이상',
          '🍎 저칼로리 식단 시도',
          '💧 물 많이 마시기',
        ];
      } else if (bmi < 30) {
        status = '비만 (운동과 식단 조절 필요)';
        recommendations = [
          '🏋️‍♂️ 근력운동과 유산소 병행',
          '🥗 저지방·고단백 식단',
          '🚶‍♀️ 매일 30분 걷기',
        ];
      } else {
        status = '고도비만 (전문적 관리 필요)';
        recommendations = [
          '👩‍⚕️ 전문의 상담 필수',
          '🚶 저강도 유산소 꾸준히',
          '🍲 영양사 상담으로 식단 조절',
        ];
      }

      setState(() {
        bmiResult = bmi.toStringAsFixed(1);
        bmiStatus = status;
        bmiRecommendations = recommendations;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ 좌측 입력폼
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildTextField(_nameController, '닉네임'),
                      const SizedBox(height: 8),
                      _buildTextField(_ageController, '나이'),
                      const SizedBox(height: 8),
                      _buildTextField(_heightController, '키(cm)'),
                      const SizedBox(height: 8),
                      _buildTextField(_weightController, '몸무게(kg)'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ✅ 우측 프로필 이미지
                Container(
                  width: MediaQuery.of(context).size.width * 0.35,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, size: 64, color: Colors.grey),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: 프로필 이미지 변경 로직
                        },
                        child: const Text('사진 변경'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculateBMI,
              child: const Text('BMI 계산하기'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text('프로필 저장'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            if (bmiResult.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BMI: $bmiResult',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('상태: $bmiStatus'),
                    const SizedBox(height: 12),
                    if (bmiRecommendations.isNotEmpty) ...[
                      const Text(
                        '💡 AI 추천 리스트',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (var item in bmiRecommendations)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }
}
