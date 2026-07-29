import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/family_provider.dart';
import 'providers/child_device_provider.dart';
import 'services/preference_service.dart';
import 'ui/auth/login_screen.dart';
import 'ui/parent/parent_dashboard.dart';
import 'ui/child/child_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase init fallback: $e');
  }

  runApp(const DOYouApp());
}

class DOYouApp extends StatelessWidget {
  const DOYouApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => ChildDeviceProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const AuthSessionRouter(),
      ),
    );
  }
}

/// Auto-Login Session Router using FirebaseAuth & SharedPreferences
class AuthSessionRouter extends StatelessWidget {
  const AuthSessionRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: PreferenceService.getSession(),
      builder: (context, prefSnapshot) {
        if (prefSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = prefSnapshot.data ?? {};
        final bool isLoggedIn = session['isLoggedIn'] ?? false;
        final String role = session['role'] ?? 'parent';

        if (isLoggedIn && role == 'child') {
          return const ChildDashboard();
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (authSnapshot.hasData && authSnapshot.data != null) {
              return const ParentDashboard();
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}
