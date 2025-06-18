import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'dart:convert';
import '../models/food_item.dart';
import '../models/user_profile.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Retry logic ile Firestore işlemi
  Future<T?> _retryFirestoreOperation<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        print('$operationName - Deneme ${attempt + 1}/$maxRetries');
        return await operation();
      } catch (e) {
        print('$operationName - Deneme ${attempt + 1} başarısız: $e');
        
        if (attempt == maxRetries - 1) {
          print('$operationName - Tüm denemeler başarısız');
          return null;
        }
        
        // Exponential backoff
        final delay = Duration(
          milliseconds: baseDelay.inMilliseconds * (1 << attempt),
        );
        print('$operationName - ${delay.inSeconds} saniye bekleyip tekrar denenecek');
        await Future.delayed(delay);
      }
    }
    return null;
  }

  // Anonim giriş
  Future<UserCredential?> signInAnonymously() async {
    try {
      print('Firebase Auth durumu kontrol ediliyor...');
      
      // Önce mevcut kullanıcıyı kontrol et
      if (_auth.currentUser != null) {
        print('Zaten giriş yapılmış: ${_auth.currentUser!.uid}');
        return null; // Zaten giriş yapılmış
      }
      
      print('Anonim giriş deneniyor...');
      final userCredential = await _auth.signInAnonymously();
      print('Anonim giriş başarılı: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth hatası: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'operation-not-allowed':
          print('Anonim authentication etkin değil. Firebase Console\'dan etkinleştirin.');
          break;
        case 'internal-error':
          print('Firebase internal error. Yapılandırmayı kontrol edin.');
          break;
        default:
          print('Bilinmeyen Firebase Auth hatası: ${e.code}');
      }
      return null;
    } catch (e) {
      print('Genel anonim giriş hatası: $e');
      return null;
    }
  }

  // Kullanıcı profili kaydetme
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      print('Profil kaydediliyor: ${profile.id}');
      await _firestore
          .collection('profiles')
          .doc(profile.id)
          .set(profile.toMap());
      print('Profil başarıyla kaydedildi: ${profile.id}');
      return true;
    } on FirebaseException catch (e) {
      print('Firebase profil kaydetme hatası: ${e.code} - ${e.message}');
      
      if (e.code == 'permission-denied') {
        print('❌ İzin hatası! Firestore Security Rules\'ları kontrol edin.');
        print('Firebase Console > Firestore > Rules bölümünde izinleri açın.');
      }
      
      return false;
    } catch (e) {
      print('Genel profil kaydetme hatası: $e');
      return false;
    }
  }

  // Kullanıcı profili getirme
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      print('Profil getiriliyor: $userId');
      DocumentSnapshot doc = await _firestore
          .collection('profiles')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        print('✅ Profil bulundu: ${doc.data()}');
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        print('ℹ️ Profil bulunamadı: $userId (Yeni kullanıcı olabilir)');
        return null;
      }
    } on FirebaseException catch (e) {
      print('❌ Firebase profil getirme hatası: ${e.code} - ${e.message}');
      
      if (e.code == 'permission-denied') {
        print('❌ İzin hatası! Firestore Security Rules\'ları kontrol edin.');
      }
      
      return null;
    } catch (e) {
      print('❌ Genel profil getirme hatası: $e');
      return null;
    }
  }

  // Resmi base64'e çevir ve Firestore'da sakla
  Future<String?> saveImageAsBase64(File imageFile, String foodItemId) async {
    try {
      print('Orijinal resim boyutu: ${await imageFile.length()} bytes');
      
      // Resmi sıkıştır
      final compressedBytes = await _compressImage(imageFile);
      if (compressedBytes == null) {
        print('Resim sıkıştırılamadı');
        return null;
      }
      
      print('Sıkıştırılmış resim boyutu: ${compressedBytes.length} bytes');
      
      // Base64'e encode et
      String base64String = base64Encode(compressedBytes);
      
      // Base64 string boyutunu kontrol et
      if (base64String.length > 1000000) { // ~1MB limit
        print('Base64 string çok büyük: ${base64String.length} karakter');
        return null;
      }
      
      print('Base64 string boyutu: ${base64String.length} karakter');
      
      // Firestore'da base64 olarak sakla - retry logic ile
      await _retryFirestoreOperation(() async {
        await _firestore
            .collection('food_images')
            .doc(foodItemId)
            .set({
              'imageData': base64String,
              'uploadedAt': FieldValue.serverTimestamp(),
              'contentType': 'image/jpeg',
              'size': compressedBytes.length,
            });
      }, 'Base64 resim kaydetme');
      
      // Base64 data URL olarak döndür
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('Base64 resim kaydetme hatası: $e');
      
      // Hata tipine göre daha detaylı log
      if (e.toString().contains('invalid-argument')) {
        print('Firestore invalid-argument hatası - resim çok büyük olabilir');
      } else if (e.toString().contains('permission-denied')) {
        print('Firestore izin hatası - Security Rules kontrol edin');
      }
      
      return null;
    }
  }

  // Base64 resmi Firestore'dan getir
  Future<String?> getImageAsBase64(String foodItemId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('food_images')
          .doc(foodItemId)
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String base64String = data['imageData'] ?? '';
        String contentType = data['contentType'] ?? 'image/jpeg';
        
        if (base64String.isNotEmpty) {
          return 'data:$contentType;base64,$base64String';
        }
      }
      return null;
    } catch (e) {
      print('Base64 resim getirme hatası: $e');
      return null;
    }
  }

  // Yemek kaydetme
  Future<bool> saveFoodItem(FoodItem foodItem) async {
    try {
      await _firestore
          .collection('food_items')
          .doc(foodItem.id)
          .set(foodItem.toMap());
      return true;
    } catch (e) {
      print('Yemek kaydetme hatası: $e');
      return false;
    }
  }

  // Kullanıcının yemek geçmişini getirme
  Future<List<FoodItem>> getUserFoodHistory(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('food_items')
          .where('userId', isEqualTo: userId)
          .orderBy('scannedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Yemek geçmişi getirme hatası: $e');
      return [];
    }
  }

  // Bugünkü yemekleri getirme
  Future<List<FoodItem>> getTodaysFoodItems(String userId) async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1));

      QuerySnapshot querySnapshot = await _firestore
          .collection('food_items')
          .where('userId', isEqualTo: userId)
          .where('scannedAt', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('scannedAt', isLessThan: endOfDay.millisecondsSinceEpoch)
          .orderBy('scannedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Bugünün yemekleri getirme hatası: $e');
      return [];
    }
  }

  // Resim sıkıştırma fonksiyonu
  Future<List<int>?> _compressImage(File imageFile) async {
    try {
      // Resmi sıkıştır - maksimum 300KB hedefle
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 800,
        minHeight: 600,
        quality: 70, // %70 kalite
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        print('Resim sıkıştırma başarısız');
        return null;
      }

      // Eğer hala çok büyükse kaliteyi daha düşür
      if (compressedBytes.length > 400000) { // 400KB'dan büyükse
        print('İkinci sıkıştırma deneniyor...');
        final secondCompress = await FlutterImageCompress.compressWithFile(
          imageFile.absolute.path,
          minWidth: 600,
          minHeight: 400,
          quality: 50, // %50 kalite
          format: CompressFormat.jpeg,
        );
        
        if (secondCompress != null && secondCompress.length < compressedBytes.length) {
          return secondCompress;
        }
      }

      return compressedBytes;
    } catch (e) {
      print('Resim sıkıştırma hatası: $e');
      // Hata durumunda orijinal resmi kullan
      try {
        final originalBytes = await imageFile.readAsBytes();
        if (originalBytes.length > 500000) { // 500KB'dan büyükse null döndür
          print('Orijinal resim çok büyük, sıkıştırma zorunlu');
          return null;
        }
        return originalBytes;
      } catch (e2) {
        print('Orijinal resim okuma hatası: $e2');
        return null;
      }
    }
  }
} 