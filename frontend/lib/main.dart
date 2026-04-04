import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/scan_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Kuriftu Cultural Whisperer',
        debugShowCheckedModeBanner: false,
        theme: KuriftuTheme.darkTheme,
        home: Consumer<AuthProvider>(
          builder: (context, auth, __) {
            // Sync notification provider with auth state after the current frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                final notifProvider = context.read<NotificationProvider>();
                notifProvider.onAuthStateChanged(auth.isAuthenticated);
              }
            });

            // While checking stored token, show a splash
            if (auth.status == AuthStatus.unknown) {
              return const _SplashScreen();
            }
            // Not authenticated → show login
            if (!auth.isAuthenticated) {
              return const LoginScreen();
            }
            // Authenticated → show welcome/main app
            return const WelcomeScreen();
          },
        ),
      ),
    );
  }
}

/// Minimal splash while auth state is being resolved
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KuriftuColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: KuriftuColors.gold, width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: KuriftuColors.gold,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
