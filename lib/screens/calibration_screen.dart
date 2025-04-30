import 'package:flutter/material.dart';
class CalibrationScreen extends StatelessWidget {
  //final VoidCallback onCalibrate;

  const CalibrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 500,
              height: 500,
              color: Colors.blueAccent,
              child: const Center(
                child: Text(
                  "Calibration Box",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: (){},
              child: const Text("Calibration OK - Go to Home"),
            ),
          ],
        ),
      ),
    );
  }
}