import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    OverlaySupport.global(
      // 👈 Bọc toàn app ở đây
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'NS2W Demo',
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
