// lib/todo_page.dart

import 'package:flutter/material.dart';

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 할 일 & 루틴'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          '이곳에 할 일 목록이 표시됩니다.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
