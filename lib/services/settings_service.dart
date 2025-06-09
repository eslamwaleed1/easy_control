import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'English';
  String _timeZone = 'UTC';

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  String get timeZone => _timeZone;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _language = prefs.getString('language') ?? 'English';
    _timeZone = prefs.getString('timeZone') ?? 'UTC';
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> setTimeZone(String value) async {
    _timeZone = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timeZone', value);
    notifyListeners();
  }

  String translate(String key) {
    const translations = {
      'English': {
        'Commands': 'Commands',
        'Voice Commands': 'Voice Commands',
        'Use these voice commands to navigate and control the app hands-free':
        'Use these voice commands to navigate and control the app hands-free',
        'Go to home': 'Go to home',
        'Navigates to the home screen': 'Navigates to the home screen',
        'Go to feedback': 'Go to feedback',
        'Opens the feedback screen to submit or view feedback':
        'Opens the feedback screen to submit or view feedback',
        'Go to profile': 'Go to profile',
        'Opens the profile screen to view user information':
        'Opens the profile screen to view user information',
        'Go to eye tracking': 'Go to eye tracking',
        'Opens the eye tracking screen for gaze-based navigation':
        'Opens the eye tracking screen for gaze-based navigation',
        'Toggle dark mode': 'Toggle dark mode',
        'Toggles between light and dark theme': 'Toggles between light and dark theme',
        'Set language to English': 'Set language to English',
        'Changes the app language to English': 'Changes the app language to English',
        'Set language to Arabic': 'Set language to Arabic',
        'Changes the app language to Arabic': 'Changes the app language to Arabic',
        'Settings': 'Settings',
        'Camera': 'Camera',
        'Microphone': 'Microphone',
        'Accessibility': 'Accessibility',
        'Disable Voice': 'Disable Voice',
        'Enable Voice': 'Enable Voice',
        'Dark Mode': 'Dark Mode',
        'Language': 'Language',
        'Time Zone': 'Time Zone',
        'Current Time': 'Current Time',
        'Gaze Flow': 'Gaze Flow',
        'Eye Tracking': 'Eye Tracking',
        'Profile': 'Profile',
        'Feedback': 'Feedback',
        'Login': 'Login',
        'Welcome Back': 'Welcome Back',
        'Username': 'Username',
        'Password': 'Password',
        'Register': 'Register',
        'Create Account': 'Create Account',
        'Email': 'Email',
        'Your Profile': 'Your Profile',
        'First Name': 'First Name',
        'Last Name': 'Last Name',
        'Date of Birth': 'Date of Birth',
        'Edit Profile': 'Edit Profile',
        'Save Profile': 'Save Profile',
        'Cancel': 'Cancel',
        'Submit Feedback': 'Submit Feedback',
        'Edit Feedback': 'Edit Feedback',
        'Message': 'Message',
        'View Your Feedback': 'View Your Feedback',
        'No feedback available': 'No feedback available',
      },
      'Arabic': {
        'Commands': 'الأوامر',
        'Voice Commands': 'الأوامر الصوتية',
        'Use these voice commands to navigate and control the app hands-free':
        'استخدم هذه الأوامر الصوتية للتنقل والتحكم في التطبيق بدون يدين',
        'Go to home': 'الانتقال إلى الصفحة الرئيسية',
        'Navigates to the home screen': 'ينتقل إلى الشاشة الرئيسية',
        'Go to feedback': 'الانتقال إلى التعليقات',
        'Opens the feedback screen to submit or view feedback':
        'يفتح شاشة التعليقات لتقديم أو عرض التعليقات',
        'Go to profile': 'الانتقال إلى الملف الشخصي',
        'Opens the profile screen to view user information':
        'يفتح شاشة الملف الشخصي لعرض معلومات المستخدم',
        'Go to eye tracking': 'الانتقال إلى تتبع العين',
        'Opens the eye tracking screen for gaze-based navigation':
        'يفتح شاشة تتبع العين للتنقل باستخدام النظر',
        'Toggle dark mode': 'تبديل الوضع الداكن',
        'Toggles between light and dark theme': 'يتبدل بين الوضع الفاتح والداكن',
        'Set language to English': 'تعيين اللغة إلى الإنجليزية',
        'Changes the app language to English': 'يغير لغة التطبيق إلى الإنجليزية',
        'Set language to Arabic': 'تعيين اللغة إلى العربية',
        'Changes the app language to Arabic': 'يغير لغة التطبيق إلى العربية',
        'Settings': 'الإعدادات',
        'Camera': 'الكاميرا',
        'Microphone': 'الميكروفون',
        'Accessibility': 'إمكانية الوصول',
        'Disable Voice': 'تعطيل الصوت',
        'Enable Voice': 'تفعيل الصوت',
        'Dark Mode': 'الوضع الداكن',
        'Language': 'اللغة',
        'Time Zone': 'المنطقة الزمنية',
        'Current Time': 'الوقت الحالي',
        'Gaze Flow': 'تدفق النظر',
        'Eye Tracking': 'تتبع العين',
        'Profile': 'الملف الشخصي',
        'Feedback': 'التعليقات',
        'Login': 'تسجيل الدخول',
        'Welcome Back': 'مرحبًا بعودتك',
        'Username': 'اسم المستخدم',
        'Password': 'كلمة المرور',
        'Register': 'التسجيل',
        'Create Account': 'إنشاء حساب',
        'Email': 'البريد الإلكتروني',
        'Your Profile': 'ملفك الشخصي',
        'First Name': 'الاسم الأول',
        'Last Name': 'الاسم الأخير',
        'Date of Birth': 'تاريخ الميلاد',
        'Edit Profile': 'تعديل الملف الشخصي',
        'Save Profile': 'حفظ الملف الشخصي',
        'Cancel': 'إلغاء',
        'Submit Feedback': 'إرسال التعليقات',
        'Edit Feedback': 'تعديل التعليقات',
        'Message': 'الرسالة',
        'View Your Feedback': 'عرض تعليقاتك',
        'No feedback available': 'لا توجد تعليقات متاحة',
      },
    };
    return translations[_language]?[key] ?? key;
  }
}