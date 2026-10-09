import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuyItBroApp());
}

class BuyItBroApp extends StatefulWidget {
  const BuyItBroApp({super.key});

  @override
  State<BuyItBroApp> createState() => _BuyItBroAppState();
}

class _BuyItBroAppState extends State<BuyItBroApp> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  Widget build(BuildContext context) {
    // Rich Modern Color Palette (Emerald + Indigo accents)
    const primaryEmerald = Color(0xFF059669);
    const secondaryIndigo = Color(0xFF4F46E5);

    return MaterialApp(
      title: 'BuyItBro - Collaborative Groceries',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryEmerald,
          primary: primaryEmerald,
          secondary: secondaryIndigo,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: primaryEmerald.withAlpha(38),
          elevation: 3,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryEmerald, width: 2),
          ),
        ),
      ),
      home: ListenableBuilder(
        listenable: _authService,
        builder: (context, _) {
          if (_authService.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (_authService.isAuthenticated) {
            return DashboardScreen(authService: _authService);
          }
          return AuthScreen(authService: _authService);
        },
      ),
    );
  }
}
