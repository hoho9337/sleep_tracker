import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart';
import 'main_page.dart';
import 'package:sleep_alarm_app/main.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  final bool isFirstLaunch;

  SplashPage({required this.isFirstLaunch});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextPage();
  }

  void _navigateToNextPage() async {
    await Future.delayed(Duration(seconds: 3));
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => widget.isFirstLaunch ? WelcomePage() : FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return snapshot.data == true ? MainPage() : LoginPage();
          }
        },
      ),
    ));
  }

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
        child: Image.asset('assets/start.png', fit: BoxFit.cover,)
    );
  }
}
