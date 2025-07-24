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
    setState(() {
      _nicknameController.text = prefs.getString('profile_nickname') ?? '';
      _ageController.text = prefs.getString('profile_age') ?? '';
      _heightController.text = prefs.getString('profile_height') ?? '';
      _weightController.text = prefs.getString('profile_weight') ?? '';
      _bmiResultText =
          prefs.getString('profile_bmiResult') ?? '키와 몸무게를 입력하면 BMI가 계산됩니다.';
    });
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_nickname', _nicknameController.text);
    await prefs.setString('profile_age', _ageController.text);
    await prefs.setString('profile_height', _heightController.text);
    await prefs.setString('profile_weight', _weightController.text);

    // BMI 계산
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);
    String bmiStatus = '';

    if (height != null && weight != null && height > 0 && weight > 0) {
      final double bmi = weight / ((height / 100) * (height / 100));

      if (bmi < 18.5) {
        bmiStatus = '저체중';
      } else if (bmi < 23) {
        bmiStatus = '정상';
      } else if (bmi < 25) {
        bmiStatus = '과체중';
      } else {
        bmiStatus = '비만';
      }

      setState(() {
        _bmiResultText = 'BMI: ${bmi.toStringAsFixed(1)} ($bmiStatus)';
      });
    } else {
      setState(() {
        _bmiResultText = '정확한 키와 몸무게를 입력해주세요.';
      });
    }

    await prefs.setString('profile_bmiResult', _bmiResultText);
    await prefs.setString('profile_bmiStatus', bmiStatus);

    if (mounted) {
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
        centerTitle: true,
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('저장하기'),
              ),
              const SizedBox(height: 32),
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
