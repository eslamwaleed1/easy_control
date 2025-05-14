import 'package:easy_control/screens/eye_tracking_screen.dart';
import 'package:easy_control/screens/feedback_screen.dart';
import 'package:easy_control/screens/home_screen.dart';
import 'package:easy_control/screens/login_screen.dart';
import 'package:easy_control/screens/profile_screen.dart';
import 'package:easy_control/screens/register_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialRoute = await _getInitialRoute();
  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> _getInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  return token != null ? '/home' : '/login';
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gaze Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
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
          case '/eye_tracking':
            builder = (context) => const EyeTrackingScreen();
            break;
          default:
            builder = (context) => const LoginScreen();
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}
