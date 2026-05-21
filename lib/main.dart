import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/screens/create_account_screen.dart';
import 'features/auth/screens/subscription_screen.dart';
import 'core/network/api_client.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/dashboard_screen.dart';
import 'features/orders/screens/add_order_screen.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.init();
  ApiClient.navigatorKey = LenseApp.navigatorKey;
  
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final role = prefs.getString('auth_user_role');
  final expiresAtStr = prefs.getString('auth_subscription_expires_at');
  
  String initialRoute = '/';
  if (token?.isNotEmpty == true) {
    if (role == 'OWNER' && expiresAtStr != null && expiresAtStr.isNotEmpty) {
      try {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          initialRoute = '/subscription';
        } else {
          initialRoute = '/dashboard';
        }
      } catch (_) {
        initialRoute = '/dashboard';
      }
    } else {
      initialRoute = '/dashboard';
    }
  }

  runApp(LenseApp(initialRoute: initialRoute));
}

class LenseApp extends StatelessWidget {
  final String initialRoute;
  
  const LenseApp({super.key, required this.initialRoute});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lense',
      navigatorKey: navigatorKey,
      scrollBehavior: MyCustomScrollBehavior(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.outfit().fontFamily, // Modern Sans
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E), // Deep Navy
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFFD4AF37), // Gold Accent
          tertiary: const Color(0xFFE0E0E0), // Soft Grey
          surface: const Color(0xFFFAF9F6), // Cream White
          error: const Color(0xFFB00020),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF9F6), // Cream Background
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          },
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1A237E), // Navy Header
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), 
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          prefixIconColor: const Color(0xFF1A237E),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(30), // Pill Shape Inputs
          ),
          focusedBorder: OutlineInputBorder(
             borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
             borderRadius: BorderRadius.circular(30),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: const Color(0xFFD4AF37), // Gold Text
            elevation: 5,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
           backgroundColor: Color(0xFF1A237E),
           foregroundColor: Color(0xFFD4AF37),
        ),
        dataTableTheme: DataTableThemeData(
           headingRowColor: WidgetStateProperty.all(const Color(0xFFE8EAF6)), 
           headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E), fontSize: 13),
           dataRowColor: WidgetStateProperty.resolveWith((states) => Colors.white),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1A237E), // Dark Nav
          indicatorColor: Colors.white.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Color(0xFFD4AF37)),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return const IconThemeData(color: Color(0xFFD4AF37)); // Gold Icons
          }),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const LoginScreen(),
        '/create-account': (context) => const CreateAccountScreen(),
        '/subscription': (context) => const SubscriptionScreen(userData: {}),
        '/dashboard': (context) => const DashboardScreen(),
        '/add_order': (context) => const AddOrderScreen(),
      },
    );
  }
}
