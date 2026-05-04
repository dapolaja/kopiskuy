import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();

  runApp(KopiskuyApp());
}

class KopiskuyApp extends StatelessWidget {
  const KopiskuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kopiskuy',
      home: LoginPage(),
    );
  }
}
