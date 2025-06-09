import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _speechEnabled = true;

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          settings.translate('Settings'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          semanticsLabel: settings.translate('Settings'),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                SettingsCard(
                  title: settings.translate('Camera'),
                  icon: Icons.camera_alt,
                  color: Colors.blue,
                  onTap: () => AppSettings.openAppSettings(type: AppSettingsType.settings),
                ),
                SizedBox(height: 10,),
                SettingsCard(
                  title: settings.translate('Microphone'),
                  icon: Icons.mic,
                  color: Colors.green,
                  onTap: () => AppSettings.openAppSettings(type: AppSettingsType.settings),
                ),SizedBox(height: 10,),
                SettingsCard(
                  title: settings.translate('Accessibility'),
                  icon: Icons.accessibility,
                  color: Colors.purple,
                  onTap: () => AppSettings.openAppSettings(type: AppSettingsType.accessibility),
                ),SizedBox(height: 10,),
              ],
            ),
            SwitchListTile(
              title: Text(
                settings.translate('Dark Mode'),
                semanticsLabel: settings.translate('Dark Mode'),
              ),
              value: settings.isDarkMode,
              onChanged: (value) => settings.toggleDarkMode(value),
              activeColor: Colors.blueAccent,
            ),SizedBox(height: 10,),
            DropdownButtonFormField<String>(
              value: settings.language,
              decoration: InputDecoration(
                labelText: settings.translate('Language'),
              ),
              items: ['English', 'Arabic']
                  .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                  .toList(),
              onChanged: (value) => settings.setLanguage(value!),
            ),
            DropdownButtonFormField<String>(
              value: settings.timeZone,
              decoration: InputDecoration(
                labelText: settings.translate('Time Zone'),
              ),
              items: ['UTC', 'EST', 'PST']
                  .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                  .toList(),
              onChanged: (value) => settings.setTimeZone(value!),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                '${settings.translate('Current Time')}: ${DateTime.now().toString().split('.')[0]} (${settings.timeZone})',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
                semanticsLabel: '${settings.translate('Current Time')} ${settings.timeZone}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;


  const SettingsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 5, // Reduced for performance
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
              semanticLabel: '$title icon',
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
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
    );
  }
}