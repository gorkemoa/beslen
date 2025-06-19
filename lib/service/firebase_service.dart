import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_profile.dart';
import '../models/food_item.dart';
import '../models/daily_summary.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth Methods
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String get userId => currentUser?.uid ?? 'anonymous';

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }

  // User Profile Methods
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .set(profile.toMap());
    } catch (e) {
      throw 'Profil kaydedilemedi: $e';
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Profil yüklenemedi: $e';
    }
  }

  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Food Items Methods
  Future<void> saveFoodItem(FoodItem foodItem, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('food_items')
          .doc(foodItem.id)
          .set(foodItem.toMap());
    } catch (e) {
      throw 'Yemek kaydedilemedi: $e';
    }
  }

  Future<List<FoodItem>> getTodaysFoodItems(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('food_items')
          .where('consumedAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('consumedAt', isLessThan: endOfDay.toIso8601String())
          .orderBy('consumedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw 'Günlük yemekler yüklenemedi: $e';
    }
  }

  Stream<List<FoodItem>> getTodaysFoodItemsStream(String userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('food_items')
        .where('consumedAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('consumedAt', isLessThan: endOfDay.toIso8601String())
        .orderBy('consumedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FoodItem.fromMap(doc.data()))
            .toList());
  }

  Future<List<FoodItem>> getFoodItemsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('food_items')
          .where('consumedAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('consumedAt', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('consumedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw 'Tarih aralığındaki yemekler yüklenemedi: $e';
    }
  }

  Future<void> deleteFoodItem(String foodItemId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('food_items')
          .doc(foodItemId)
          .delete();
    } catch (e) {
      throw 'Yemek silinemedi: $e';
    }
  }

  // Daily Summary Methods
  Future<void> saveDailySummary(DailySummary summary) async {
    try {
      final dateKey = summary.date.toIso8601String().split('T')[0];
      await _firestore
          .collection('users')
          .doc(summary.userId)
          .collection('daily_summaries')
          .doc(dateKey)
          .set(summary.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw 'Günlük özet kaydedilemedi: $e';
    }
  }

  Future<DailySummary?> getDailySummary(String userId, DateTime date) async {
    try {
      final dateKey = date.toIso8601String().split('T')[0];
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_summaries')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        return DailySummary.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Günlük özet yüklenemedi: $e';
    }
  }

  Stream<DailySummary?> getDailySummaryStream(String userId, DateTime date) {
    final dateKey = date.toIso8601String().split('T')[0];
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_summaries')
        .doc(dateKey)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return DailySummary.fromMap(doc.data()!);
      }
      return null;
    });
  }

  Future<List<DailySummary>> getDailySummariesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startKey = startDate.toIso8601String().split('T')[0];
      final endKey = endDate.toIso8601String().split('T')[0];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_summaries')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
          .orderBy(FieldPath.documentId, descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DailySummary.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw 'Tarih aralığındaki günlük özetler yüklenemedi: $e';
    }
  }

  // Image Upload
  Future<String> uploadFoodImage(File imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage
          .ref()
          .child('food_images')
          .child(userId)
          .child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Resim yüklenemedi: $e';
    }
  }

  // Statistics
  Future<Map<String, double>> getWeeklyCalorieStats(String userId) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      
      final foods = await getFoodItemsByDateRange(userId, startDate, endDate);
      
      Map<String, double> dailyCalories = {};
      
      for (final food in foods) {
        final dateKey = food.consumedAt.toIso8601String().split('T')[0];
        dailyCalories[dateKey] = (dailyCalories[dateKey] ?? 0) + food.nutritionInfo.calories;
      }
      
      return dailyCalories;
    } catch (e) {
      throw 'Haftalık istatistikler yüklenemedi: $e';
    }
  }
} 