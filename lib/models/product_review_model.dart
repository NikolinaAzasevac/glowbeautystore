class ProductReviewModel {
  const ProductReviewModel({
    required this.reviewId,
    required this.productId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.reviewerName,
    required this.date,
  });

  final String reviewId;
  final String productId;
  final String userId;
  final int rating;
  final String comment;
  final String reviewerName;
  final DateTime? date;

  factory ProductReviewModel.fromMap(Map<String, dynamic> data) {
    return ProductReviewModel(
      reviewId: (data['reviewId'] ?? '').toString(),
      productId: (data['productId'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      rating: data['rating'] is num ? (data['rating'] as num).round() : 0,
      comment: (data['comment'] ?? '').toString(),
      reviewerName: (data['reviewerName'] ?? 'Glow Customer').toString(),
      date: DateTime.tryParse((data['date'] ?? '').toString()),
    );
  }

  factory ProductReviewModel.fromFirestoreMap(
    String reviewId,
    Map<String, dynamic> data,
  ) {
    final rawCreatedAt = data['createdAt'];
    return ProductReviewModel(
      reviewId: reviewId,
      productId: (data['productId'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      rating: data['rating'] is num ? (data['rating'] as num).round() : 0,
      comment: (data['comment'] ?? '').toString(),
      reviewerName: (data['userName'] ?? 'Glow Customer').toString(),
      date: rawCreatedAt is DateTime ? rawCreatedAt : rawCreatedAt?.toDate(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'reviewId': reviewId,
      'productId': productId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'userName': reviewerName,
      'createdAt': date,
    };
  }
}
