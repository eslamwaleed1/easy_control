class FeedbackModel {
  final int feedbackId;
  final String userId;
  final DateTime submittedAt;
  final String message;
  final int rating;

  FeedbackModel({
    required this.feedbackId,
    required this.userId,
    required this.submittedAt,
    required this.message,
    required this.rating,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      feedbackId: json['feedbackId'] as int,
      userId: json['userId'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      message: json['message'] as String,
      rating: json['rating'] as int,
    );
  }
}