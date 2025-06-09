import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
//import '../services/settings_provider.dart';
import 'dart:io' show Platform;

import '../services/settings_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    print('Running on API level: ${Platform.version}');
    _loadProfile();
  }

  void _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _apiService.getProfile();
      print('Profile data: $profile');
      setState(() {
        _profile = profile;
        _firstNameController.text = profile['firstName'] ?? '';
        _lastNameController.text = profile['lastName'] ?? '';
        if (profile['dateOfBirth'] != null && profile['dateOfBirth'].isNotEmpty) {
          final parsedDate = DateTime.tryParse(profile['dateOfBirth']);
          _selectedDate = parsedDate != null && parsedDate.year >= 1900 ? parsedDate : null;
          print('Parsed dateOfBirth: $_selectedDate');
        } else {
          _selectedDate = null;
          print('No valid dateOfBirth in profile');
        }
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateProfile() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (_selectedDate == null) {
      setState(() {
        _errorMessage = 'Please select a ' + settings.translate('Date of Birth').toLowerCase();
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final updatedProfile = await _apiService.createProfile(
        _firstNameController.text,
        _lastNameController.text,
        _selectedDate!.toIso8601String().split('T')[0],
      );
      print('Updated profile: $updatedProfile');
      setState(() {
        _isEditing = false;
        _errorMessage = null;
      });
      _loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(settings.translate('Profile') + ' updated')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    print('Date picker tapped');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        print('Selected date: ${_selectedDate!.toIso8601String()}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(settings.translate('Profile')),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                settings.translate('Your Profile'),
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                semanticsLabel: settings.translate('Your Profile'),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                Text(
                  'Error: $_errorMessage',
                  style: theme.textTheme.bodyMedium!.copyWith(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _loadProfile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        settings.translate('Retry'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (_profile != null && !_isEditing) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${settings.translate('First Name')}: ${_profile!['firstName'] ?? 'N/A'}',
                          style: theme.textTheme.bodyMedium!.copyWith(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${settings.translate('Last Name')}: ${_profile!['lastName'] ?? 'N/A'}',
                          style: theme.textTheme.bodyMedium!.copyWith(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${settings.translate('Date of Birth')}: ${_profile!['dateOfBirth'] != null ? DateTime.parse(_profile!['dateOfBirth']).toString().split(' ')[0] : 'N/A'}',
                          style: theme.textTheme.bodyMedium!.copyWith(fontSize: 32),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _isEditing = true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 32,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        settings.translate('Edit Profile'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_profile == null && !_isEditing) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      settings.translate('No feedback available'),
                      style: theme.textTheme.bodyMedium!.copyWith(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _loadProfile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 32,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        settings.translate('Retry'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_isEditing) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: settings.translate('First Name'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: settings.translate('Last Name'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.inputDecorationTheme.fillColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate != null
                                        ? _selectedDate!.toString().split(' ')[0]
                                        : settings.translate('Date of Birth'),
                                    style: TextStyle(
                                      color: _selectedDate != null
                                          ? theme.textTheme.bodyMedium!.color
                                          : Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, color: Colors.blue),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _updateProfile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 32,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        settings.translate('Save Profile'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _isEditing = false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 32,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        settings.translate('Cancel'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}