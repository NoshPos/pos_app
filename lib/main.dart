import 'package:flutter/material.dart';
import 'package:pos_app/features/onboarding/view/pages/login_page.dart';
import 'package:pos_app/features/onboarding/view/pages/onboarding_page.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS APP',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}



