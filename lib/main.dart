import 'dart:io';

import 'package:ebooks/app_util.dart';
import 'package:ebooks/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  changeStatusBarColor();
  deleteExpiredBooks();

  runApp(const Splash());
}

changeStatusBarColor() async {
  await FlutterStatusbarcolor.setStatusBarColor(const Color(0xff500a34));
  if (useWhiteForeground(const Color(0xff500a34))) {
    FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
  } else {
    FlutterStatusbarcolor.setStatusBarWhiteForeground(false);
  }
}

deleteExpiredBooks() async {
  var result = await AppUtil().readBooks();
  result.forEach((item) {
    final directory = Directory(item.path);
    final now = DateTime.now();
    final lastModified = File(directory.path).statSync().modified;
    final difference = now.difference(lastModified);
    if (difference.inDays >= 365) {
      directory.deleteSync(recursive: true);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text("ebook");
  }
}
