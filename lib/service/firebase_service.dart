import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_profile.dart';
import '../models/food_item.dart';
import '../models/daily_summary.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth Methods
  User? get currentUser => _auth.currentUser;
  
  String? get currentUserId => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Giriş yapılamadı: $e');
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Hesap oluşturulamadı: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // User Profile Methods
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .set(profile.toJson());
    } catch (e) {
      throw Exception('Profil kaydedilemedi: $e');
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Profil alınamadı: $e');
    }
  }

  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return UserProfile.fromJson(doc.data()!);
          }
          return null;
        });
  }

  // Food Items Methods
  Future<String> saveFoodItem(FoodItem foodItem) async {
    try {
      final docRef = await _firestore
          .collection('food_items')
          .add(foodItem.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Yemek kaydedilemedi: $e');
    }
  }

  Future<List<FoodItem>> getUserFoods(String userId, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('food_items')
          .where('userId', isEqualTo: userId)
          .orderBy('scannedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => FoodItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Yemek geçmişi alınamadı: $e');
    }
  }

  Stream<List<FoodItem>> getUserFoodsStream(String userId) {
    return _firestore
        .collection('food_items')
        .where('userId', isEqualTo: userId)
        .orderBy('scannedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FoodItem.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  Future<List<FoodItem>> getTodaysFoods(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final query = await _firestore
          .collection('food_items')
          .where('userId', isEqualTo: userId)
          .where('scannedAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('scannedAt', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .orderBy('scannedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => FoodItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Bugünün yemekleri alınamadı: $e');
    }
  }

  // Image Upload Methods
  Future<String> uploadFoodImage(File imageFile, String userId) async {
    try {
      final fileName = 'food_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Görsel yüklenemedi: $e');
    }
  }

  // Daily Summary Methods
  Future<void> saveDailySummary(DailySummary summary) async {
    try {
      await _firestore
          .collection('daily_summaries')
          .doc(summary.id)
          .set(summary.toJson());
    } catch (e) {
      throw Exception('Günlük özet kaydedilemedi: $e');
    }
  }

  Future<DailySummary?> getDailySummary(String userId, DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final summaryId = '${userId}_$dateStr';
      
      final doc = await _firestore
          .collection('daily_summaries')
          .doc(summaryId)
          .get();

      if (doc.exists && doc.data() != null) {
        return DailySummary.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Günlük özet alınamadı: $e');
    }
  }

  // Utility Methods
  Future<void> deleteFoodItem(String foodId) async {
    try {
      await _firestore.collection('food_items').doc(foodId).delete();
    } catch (e) {
      throw Exception('Yemek silinemedi: $e');
    }
  }

  Future<void> updateFoodItem(String foodId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('food_items').doc(foodId).update(updates);
    } catch (e) {
      throw Exception('Yemek güncellenemedi: $e');
    }
  }
} 