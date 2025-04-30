import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onFirstButtonPressed;
  final VoidCallback onSecondButtonPressed;

  const HomeScreen({
    super.key,
    required this.onFirstButtonPressed,
    required this.onSecondButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gaze Tracker',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: onFirstButtonPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blueAccent,
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text("Calibrate"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onSecondButtonPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.deepPurple,
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text("Open OS View"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
