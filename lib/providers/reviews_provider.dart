import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glow_beauty_store/models/product_review_model.dart';

class ReviewsProvider with ChangeNotifier {
  final CollectionReference<Map<String, dynamic>> _reviewsDb =
      FirebaseFirestore.instance.collection('reviews');

  Stream<List<ProductReviewModel>> reviewsStream(String productId) {
    return _reviewsDb
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => ProductReviewModel.fromFirestoreMap(doc.id, doc.data()))
          .toList();
      reviews.sort((a, b) {
        final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return reviews;
    });
  }

  Future<void> addReview({
    required String productId,
    required int rating,
    required String comment,
    required String userName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please login before writing a review.');
    }

    final docRef = _reviewsDb.doc();
    await docRef.set({
      'reviewId': docRef.id,
      'productId': productId,
      'userId': user.uid,
      'rating': rating,
      'comment': comment.trim(),
      'userName': userName,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    required String userName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please login before editing a review.');
    }

    final doc = await _reviewsDb.doc(reviewId).get();
    if (!doc.exists) {
      throw Exception('Review no longer exists.');
    }
    if (doc.data()?['userId'] != user.uid) {
      throw Exception('You can only edit your own review.');
    }

    await _reviewsDb.doc(reviewId).update({
      'rating': rating,
      'comment': comment.trim(),
      'userName': userName,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> deleteReview(String reviewId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please login before deleting a review.');
    }
    final doc = await _reviewsDb.doc(reviewId).get();
    if (!doc.exists) {
      return;
    }
    if (doc.data()?['userId'] != user.uid) {
      throw Exception('You can only delete your own review.');
    }
    await _reviewsDb.doc(reviewId).delete();
  }
}
