import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
          children: [
            FeatureCard(
              title: 'Eye Tracking',
              icon: Icons.visibility,
              color: Colors.blueAccent,
              onTap: () {
                Navigator.pushNamed(context, '/eye_tracking');
              },
            ),
            FeatureCard(
              title: 'Profile',
              icon: Icons.person,
              color: Colors.purple,
              onTap: () {
                print('Profile tapped - implement later');
              },
            ),
            FeatureCard(
              title: 'Voice Commands',
              icon: Icons.mic,
              color: Colors.red,
              onTap: () {
                print('Voice Commands tapped - implement later');
              },
            ),
          ],
        ),
      ),
    );
  }
}