
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final _formKey = GlobalKey<FormState>();
final _usernameController = TextEditingController();
final _passwordController = TextEditingController();
bool _isLoading = false;
String? _errorMessage;

@override
void initState() {
super.initState();
_checkAuth();
}

Future<void> _checkAuth() async {
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('jwt_token');
if (token != null) {
Navigator.pushReplacementNamed(context, '/home');
}
}

@override
void dispose() {
_usernameController.dispose();
_passwordController.dispose();
super.dispose();
}

Future<void> _login() async {
if (!_formKey.currentState!.validate()) return;

setState(() {
_isLoading = true;
_errorMessage = null;
});

try {
await ApiService().login(
_usernameController.text.trim(),
_passwordController.text.trim(),
);
if (!mounted) return;
Navigator.pushReplacementNamed(context, '/home');
} catch (e) {
setState(() {
_errorMessage = e.toString().replaceFirst('Exception: ', '');
});
} finally {
setState(() {
_isLoading = false;
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Login')),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: Form(
key: _formKey,
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
TextFormField(
controller: _usernameController,
decoration: const InputDecoration(
labelText: 'Username',
border: OutlineInputBorder(),
),
validator: (value) =>
value!.isEmpty ? 'Username is required' : null,
),
const SizedBox(height: 16),
TextFormField(
controller: _passwordController,
decoration: const InputDecoration(
labelText: 'Password',
border: OutlineInputBorder(),
),
obscureText: true,
validator: (value) =>
value!.isEmpty ? 'Password is required' : null,
),
const SizedBox(height: 16),
if (_errorMessage != null)
Text(
_errorMessage!,
style: const TextStyle(color: Colors.red),
),
const SizedBox(height: 16),
_isLoading
? const CircularProgressIndicator()
    : ElevatedButton(
onPressed: _login,
child: const Text('Login'),
),
const SizedBox(height: 8),
TextButton(
onPressed: () {
Navigator.pushNamed(context, '/register');
},
child: const Text('Don\'t have an account? Register'),
),
],
),
),
),
);
}
}
