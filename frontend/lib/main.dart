import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/scan_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: KuriftuColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const CulturalWhispererApp());
}

class CulturalWhispererApp extends StatelessWidget {
  const CulturalWhispererApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Kuriftu Cultural Whisperer',
        debugShowCheckedModeBanner: false,
        theme: KuriftuTheme.darkTheme,
        home: const WelcomeScreen(),
      ),
    );
  }
}
