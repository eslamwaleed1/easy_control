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

  Future<void> _loadFeedbacks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final feedbacks = await _apiService.getFeedbacks();
      if (mounted) {
        setState(() {
          _feedbacks = feedbacks.map((f) => FeedbackModel.fromJson(f)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitFeedback() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (_messageController.text.isEmpty) {
      setState(
        () => _errorMessage = settings.translate('Message') + ' is required',
      );
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
          SnackBar(
            content: Text(settings.translate('Feedback') + ' submitted'),
          ),
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

  Future<void> _updateFeedback() async {
    if (_editingFeedbackId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _apiService.updateFeedback(
        _editingFeedbackId!,
        _messageController.text,
        _rating,
      );
      await _loadFeedbacks();
      setState(() {
        _isEditing = false;
        _editingFeedbackId = null;
        _messageController.clear();
        _rating = 1;
      });
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
      appBar: AppBar(
        title: Text(
          settings.translate('Feedback'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          semanticsLabel: settings.translate('Feedback'),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.translate('Share Your Experience'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        settings.translate('Help us improve Gaze Flow'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodyLarge?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: ListView(
                          children: [
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settings.translate('Your Feedback'),
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        hintText: settings.translate(
                                          'Type your message here...',
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                      ),
                                      maxLines: 3,
                                      maxLength: 1000,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      settings.translate('Rating'),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(5, (index) {
                                        return IconButton(
                                          icon: Icon(
                                            index < _rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color:
                                                index < _rating
                                                    ? Colors.amber
                                                    : Colors.grey,
                                            size: 32,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _rating = index + 1;
                                            });
                                          },
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isEditing
                                                ? _updateFeedback
                                                : _submitFeedback,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 4,
                                        ),
                                        child: Text(
                                          _isEditing
                                              ? settings.translate(
                                                'Update Feedback',
                                              )
                                              : settings.translate(
                                                'Submit Feedback',
                                              ),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_feedbacks != null &&
                                _feedbacks!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                settings.translate('Previous Feedback'),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._feedbacks!.map(
                                (feedback) => Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: List.generate(5, (
                                                index,
                                              ) {
                                                return Icon(
                                                  index < feedback.rating
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color:
                                                      index < feedback.rating
                                                          ? Colors.amber
                                                          : Colors.grey,
                                                  size: 20,
                                                );
                                              }),
                                            ),
                                            Text(
                                              feedback.submittedAt
                                                  .toString()
                                                  .split('.')[0],
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color
                                                        ?.withOpacity(0.7),
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          feedback.message,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        if (feedback.feedbackId ==
                                            _editingFeedbackId) ...[
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: _cancelEdit,
                                                child: Text(
                                                  settings.translate('Cancel'),
                                                  style: TextStyle(
                                                    color: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color
                                                        ?.withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
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
