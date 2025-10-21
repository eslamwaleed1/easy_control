import 'package:easy_control/screens/commands_screen.dart';
import 'package:easy_control/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/eye_tracking_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialRoute = await _getInitialRoute();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

Future<String> _getInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  // final token = null;
  return token != null ? '/home' : '/login';
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Gaze Tracker',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[100],
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blueAccent,
              titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[200],
              labelStyle: TextStyle(color: Colors.grey[700]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black87),
            ),
            useMaterial3: false,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.grey[900],
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blueAccent,
              titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[800],
              labelStyle: TextStyle(color: Colors.grey[300]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[600]!),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white),
            ),
            useMaterial3: false,
          ),
          themeMode: settings!.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: initialRoute,
          onGenerateRoute: (settings) {
            WidgetBuilder builder;
            switch (settings.name) {
              case '/login':
                builder = (context) => const LoginScreen();
                break;
              case '/register':
                builder = (context) => const RegisterScreen();
                break;
              case '/profile':
                builder = (context) => const ProfileScreen();
                break;
              case '/home':
                builder = (context) => const HomeScreen();
                break;
              case '/feedback':
                builder = (context) => const FeedbackScreen();
                break;
              case '/settings':
                builder = (context) => const SettingsScreen();
                break;
              case '/eye_tracking':
                builder = (context) => const EyeTrackingScreen();
                break;
              case '/commands':
                builder = (context)=> const CommandsScreen();
                break;
              default:
                builder = (context) => const LoginScreen();
            }
            return MaterialPageRoute(builder: builder, settings: settings);
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}