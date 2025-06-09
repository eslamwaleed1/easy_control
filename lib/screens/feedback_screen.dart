import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/feedback_model.dart';
import '../services/api_service.dart';
//import '../services/settings_provider.dart';
import '../services/settings_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final ApiService _apiService = ApiService();
  List<FeedbackModel>? _feedbacks;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  final _messageController = TextEditingController();
  int _rating = 1;
  int? _editingFeedbackId;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  void _loadFeedbacks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final feedbacks = await _apiService.getFeedbacks();
      setState(() {
        _feedbacks = feedbacks.map((f) => FeedbackModel.fromJson(f)).toList();
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submitFeedback() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (_messageController.text.isEmpty) {
      setState(() => _errorMessage = settings.translate('Message') + ' is required');
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isEditing && _editingFeedbackId != null) {
        await _apiService.updateFeedback(
          _editingFeedbackId!,
          _messageController.text,
          _rating,
        );
        setState(() {
          _isEditing = false;
          _editingFeedbackId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(settings.translate('Feedback') + ' updated')),
        );
      } else {
        await _apiService.createFeedback(_messageController.text, _rating);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(settings.translate('Feedback') + ' submitted')),
        );
      }
      _messageController.clear();
      setState(() => _rating = 1);
      _loadFeedbacks();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editFeedback(FeedbackModel feedback) {
    setState(() {
      _isEditing = true;
      _editingFeedbackId = feedback.feedbackId;
      _messageController.text = feedback.message;
      _rating = feedback.rating;
    });
  }

  void _deleteFeedback(int id) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await _apiService.deleteFeedback(id);
      _loadFeedbacks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(settings.translate('Feedback') + ' deleted')),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editingFeedbackId = null;
      _messageController.clear();
      _rating = 1;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(settings.translate('Feedback')),
        backgroundColor: theme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _isEditing ? settings.translate('Edit Feedback') : settings.translate('Submit Feedback'),
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                semanticsLabel: _isEditing ? settings.translate('Edit Feedback') : settings.translate('Submit Feedback'),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                Text(
                  'Error: $_errorMessage',
                  style: theme.textTheme.bodyMedium!.copyWith(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
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
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: settings.translate('Message'),
                        ),
                        maxLines: 3,
                        maxLength: 1000,
                      ),
                      const SizedBox(height: 16),
                      DropdownButton<int>(
                        value: _rating,
                        items: [1, 2, 3, 4, 5].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value Star${value > 1 ? 's' : ''}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _rating = value!);
                        },
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
                  onTap: _submitFeedback,
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
                      _isEditing ? settings.translate('Edit Feedback') : settings.translate('Submit Feedback'),
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
              if (_isEditing) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _cancelEdit,
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
              const SizedBox(height: 32),
              ExpansionTile(
                title: Text(
                  settings.translate('View Your Feedback'),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                initiallyExpanded: false,
                children: [
                  if (_feedbacks != null && _feedbacks!.isNotEmpty) ...[
                    ..._feedbacks!.map((feedback) => Card(
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
                              'Rating: ${feedback.rating} Star${feedback.rating > 1 ? 's' : ''}',
                              style: theme.textTheme.bodyMedium!.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              feedback.message,
                              style: theme.textTheme.bodyMedium!.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${settings.translate('Submitted')}: ${feedback.submittedAt.toString().split(' ')[0]}',
                              style: theme.textTheme.bodyMedium!.copyWith(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () => _editFeedback(feedback),
                                  child: Text(
                                    settings.translate('Edit'),
                                    style: const TextStyle(color: Colors.blue, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                InkWell(
                                  onTap: () => _deleteFeedback(feedback.feedbackId),
                                  child: Text(
                                    settings.translate('Delete'),
                                    style: const TextStyle(color: Colors.red, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        settings.translate('No feedback available'),
                        style: theme.textTheme.bodyMedium!.copyWith(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}