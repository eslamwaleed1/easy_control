import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          settings.translate('Gaze Flow'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          semanticsLabel: settings.translate('Gaze Flow'),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.translate('Welcome to Gaze Flow'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
              semanticsLabel: settings.translate('Welcome to Gaze Flow'),
            ),
            const SizedBox(height: 8),
            Text(
              settings.translate('Select a feature to get started'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.2,
                children: [
                  FeatureCard(
                    title: settings.translate('Eye Tracking'),
                    icon: Icons.visibility,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pushNamed(context, '/eye_tracking');
                    },
                  ),
                  FeatureCard(
                    title: settings.translate('Profile'),
                    icon: Icons.person,
                    color: Colors.green,
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  FeatureCard(
                    title: settings.translate('Feedback'),
                    icon: Icons.feedback,
                    color: Colors.pink,
                    onTap: () {
                      Navigator.pushNamed(context, '/feedback');
                    },
                  ),
                  FeatureCard(
                    title: settings.translate('Settings'),
                    icon: Icons.settings,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  FeatureCard(
                    title: settings.translate('Commands'),
                    icon: Icons.voice_chat_rounded,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pushNamed(context, '/commands');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
                semanticLabel: '$title icon',
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                semanticsLabel: title,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
