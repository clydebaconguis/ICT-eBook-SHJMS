import 'dart:io';

import 'package:ebooks/app_util.dart';
import 'package:ebooks/pages/nav_main.dart';
import 'package:ebooks/signup_login/sign_in.dart';
import 'package:ebooks/welcome/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  late bool loggedIn = false;
  late bool expired = false;

  checkLoginStatus() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    if (token != null) {
      setState(() {
        loggedIn = true;
      });
    }
  }

  checkExpiration() async {
    List<FileSystemEntity> result = await AppUtil().readBooks();
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var exp = localStorage.getString('expiry');
    // var expiration = '2023-08-09';
    if (exp != null) {
      final expDate = DateTime.parse(exp);
      final now = DateTime.now();
      if (now.isAfter(expDate) || now.isAtSameMomentAs(expDate)) {
        EasyLoading.showInfo('Subscription Expired!');
        if (result.isNotEmpty) {
          for (var item in result) {
            final directory = Directory(item.path);
            directory.deleteSync(recursive: true);
            print("Deleted directory: ${directory.path}");
          }
        } else {
          print("No books found.");
        }
        logout();
        if (mounted) {
          setState(() {
            expired = true;
          });
        }
      }
    } else {
      checkLoginStatus();
    }
  }

  logout() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    await localStorage.clear();
  }

  @override
  void initState() {
    checkExpiration();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '',
      home: AnimatedSplashScreen(
        splashIconSize: 100,
        duration: 2000,
        centered: true,
        splash: 'img/liceo-logo.png',
        nextScreen: expired
            ? const SignIn()
            : loggedIn
                ? const MyNav()
                : const Welcome(),
        splashTransition: SplashTransition.sizeTransition,
        pageTransitionType: PageTransitionType.fade,
        backgroundColor: Colors.white,
      ),
      builder: EasyLoading.init(),
    );
  }
}
