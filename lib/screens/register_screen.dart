
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
const RegisterScreen({super.key});

@override
State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
final _formKey = GlobalKey<FormState>();
final _usernameController = TextEditingController();
final _emailController = TextEditingController();
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
_emailController.dispose();
_passwordController.dispose();
super.dispose();
}

Future<void> _register() async {
if (!_formKey.currentState!.validate()) return;

setState(() {
_isLoading = true;
_errorMessage = null;
});

try {
await ApiService().register(
_usernameController.text.trim(),
_emailController.text.trim(),
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
appBar: AppBar(title: const Text('Register')),
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
controller: _emailController,
decoration: const InputDecoration(
labelText: 'Email',
border: OutlineInputBorder(),
),
keyboardType: TextInputType.emailAddress,
validator: (value) {
if (value!.isEmpty) return 'Email is required';
if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
return 'Enter a valid email';
}
return null;
},
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
onPressed: _register,
child: const Text('Register'),
),
const SizedBox(height: 8),
TextButton(
onPressed: () {
Navigator.pushNamed(context, '/login');
},
child: const Text('Already have an account? Login'),
),
],
),
),
),
);
}
}
