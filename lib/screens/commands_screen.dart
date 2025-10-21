import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';

class CommandsScreen extends StatelessWidget {
  const CommandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    // List of gesture commands and their descriptions (English only)
    final commands = [
      {
        'command': 'tap',
        'description': 'Performs a quick touch at a specific point',
      },
      {
        'command': 'press',
        'description': 'Performs a quick touch at a specific point',
      },
      {
        'command': 'open',
        'description': 'Performs a quick touch at a specific point',
      },
      {
        'command': 'hold',
        'description': 'Performs a longer touch at a specific point',
      },
      {
        'command': 'long tap',
        'description': 'Performs a longer touch at a specific point',
      },
      {
        'command': 'long press',
        'description': 'Performs a longer touch at a specific point',
      },
      {
        'command': 'twice',
        'description': 'Performs a double touch at a specific point',
      },
      {
        'command': 'double tap',
        'description': 'Performs a double touch at a specific point',
      },
      {
        'command': 'double press',
        'description': 'Performs a double touch at a specific point',
      },
      {
        'command': 'swipe left',
        'description': 'Performs a swipe at a specific point',
      },
      {
        'command': 'swipe right',
        'description': 'Performs a swipe at a specific point',
      },
      {
        'command': 'swipe up',
        'description': 'Performs a swipe at a specific point',
      },
      {
        'command': 'swipe down',
        'description': 'Performs a swipe at a specific point',
      },
      {
        'command': 'home',
        'description': 'Goes to home screen',
      },
      {
        'command': 'go back',
        'description': 'Goes back one time',
      },
      {
        'command': 'running',
        'description': 'Opens notifications',
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          settings.translate('Commands'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          semanticsLabel: settings.translate('Commands'),
        ),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.translate('Gesture Commands'),
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                semanticsLabel: settings.translate('Gesture Commands'),
              ),
              const SizedBox(height: 16),
              Text(
                settings.translate('Use these gesture commands to interact with the app via touch actions'),
                style: theme.textTheme.bodyMedium!.copyWith(fontSize: 16),
                semanticsLabel: settings.translate('Use these gesture commands to interact with the app via touch actions'),
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: commands.length,
                itemBuilder: (context, index) {
                  final command = commands[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Semantics(
                      label: 'Gesture command: ${command['command']}, ${command['description']}',
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"${command['command']}"',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                                semanticsLabel: command['command'],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                command['description']!,
                                style: theme.textTheme.bodyMedium!.copyWith(fontSize: 16),
                                semanticsLabel: command['description'],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}