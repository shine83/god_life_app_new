import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _bmiResultText = '키와 몸무게를 입력하면 BMI가 계산됩니다.';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nicknameController.text = prefs.getString('profile_nickname') ?? '';
      _ageController.text = prefs.getString('profile_age') ?? '';
      _heightController.text = prefs.getString('profile_height') ?? '';
      _weightController.text = prefs.getString('profile_weight') ?? '';
      _bmiResultText =
          prefs.getString('profile_bmiResult') ?? '키와 몸무게를 입력하면 BMI가 계산됩니다.';
    });
  }

  // lib/profile_page.dart 파일 안에 있는 _saveProfileData 함수를 교체해주세요.

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_nickname', _nicknameController.text);
    await prefs.setString('profile_age', _ageController.text);
    await prefs.setString('profile_height', _heightController.text);
    await prefs.setString('profile_weight', _weightController.text);

    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    // ✅ 1. 결과를 담을 '임시 변수'를 만듭니다.
    String newBmiResultText;

    if (height != null && weight != null && height > 0 && weight > 0) {
      final double bmi = weight / ((height / 100) * (height / 100));
      String bmiStatus = '';

      if (bmi < 18.5) {
        bmiStatus = '저체중';
      } else if (bmi < 25) {
        bmiStatus = '정상';
      } else {
        bmiStatus = '비만';
      }

      // ✅ 2. 계산된 결과를 임시 변수에 저장합니다.
      newBmiResultText = 'BMI: ${bmi.toStringAsFixed(1)} ($bmiStatus)';
    } else {
      newBmiResultText = '정확한 키와 몸무게를 입력해주세요.';
    }

    // ✅ 3. '임시 변수'의 확실한 값을 저장하고, 출력하고, 화면에 반영합니다.
    await prefs.setString('profile_bmiResult', newBmiResultText);
    print('✅ BMI 저장됨: $newBmiResultText');

    if (mounted) {
      setState(() {
        _bmiResultText = newBmiResultText;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 설정'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: '나이',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: '키 (cm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: '몸무게 (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProfileData,
                style: ElevatedButton.styleFrom(
                  // ✅ [수정된 부분] 배경색과 글자색을 명확히 지정합니다.
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('프로필 저장하기'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _bmiResultText,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
