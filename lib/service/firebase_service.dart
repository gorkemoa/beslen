import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../models/water_intake.dart';
import '../models/sleep_record.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // E-posta ile giriş
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      print('E-posta ile giriş deneniyor: $email');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('E-posta girişi başarılı: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('E-posta giriş hatası: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Genel e-posta giriş hatası: $e');
      throw e;
    }
  }

  // E-posta ile kayıt
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      print('E-posta ile kayıt deneniyor: $email');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('E-posta kaydı başarılı: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('E-posta kayıt hatası: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Genel e-posta kayıt hatası: $e');
      throw e;
    }
  }

  // Google ile giriş
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Google ile giriş deneniyor...');
      
      // Google Sign-In işlemi
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google giriş iptal edildi');
        return null;
      }

      // Google authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase credential oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'e giriş yap
      final userCredential = await _auth.signInWithCredential(credential);
      print('Google girişi başarılı: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Google Firebase Auth hatası: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Genel Google giriş hatası: $e');
      throw e;
    }
  }

  // Apple ile giriş
  Future<UserCredential?> signInWithApple() async {
    try {
      print('Apple ile giriş deneniyor...');
      
      // Apple Sign-In için random nonce oluştur
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // Apple Sign-In request
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Firebase credential oluştur
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Firebase'e giriş yap
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      print('Apple girişi başarılı: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Apple Firebase Auth hatası: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Genel Apple giriş hatası: $e');
      throw e;
    }
  }

  // Şifre sıfırlama
  Future<bool> resetPassword(String email) async {
    try {
      print('Şifre sıfırlama e-postası gönderiliyor: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('Şifre sıfırlama e-postası gönderildi');
      return true;
    } on FirebaseAuthException catch (e) {
      print('Şifre sıfırlama hatası: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Genel şifre sıfırlama hatası: $e');
      return false;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      // Önce Google Sign-In'den çıkış yapmayı deneyelim
      try {
        await _googleSignIn.signOut();
        print('Google Sign-In çıkışı başarılı');
      } catch (e) {
        print('Google Sign-In çıkış hatası (göz ardı edildi): $e');
        // Google Sign-In hatası olsa bile Firebase çıkışına devam et
      }
      
      // Firebase'den çıkış yap
      await _auth.signOut();
      print('Firebase çıkışı başarılı');
    } catch (e) {
      print('Firebase çıkış hatası: $e');
      throw e; // Firebase çıkış hatası kritik, yukarı fırlat
    }
  }

  // Random nonce oluşturucu (Apple Sign-In için)
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // Kullanıcı profili kaydetme
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      print('Profil kaydediliyor: ${profile.id}');
      await _firestore
          .collection('users')
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
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        print('✅ Profil bulundu: ${doc.data()}');
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>, userId);
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

  // Su tüketimi kaydetme
  Future<bool> saveWaterIntake(WaterIntake waterIntake) async {
    try {
      await _firestore
          .collection('water_intake')
          .doc(waterIntake.id)
          .set(waterIntake.toMap());
      print('Su tüketimi kaydedildi: ${waterIntake.amount}ml');
      return true;
    } catch (e) {
      print('Su tüketimi kaydetme hatası: $e');
      return false;
    }
  }

  // Bugünkü su tüketimini getirme
  Future<List<WaterIntake>> getTodaysWaterIntake(String userId) async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1));

      QuerySnapshot querySnapshot = await _firestore
          .collection('water_intake')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('timestamp', isLessThan: endOfDay.millisecondsSinceEpoch)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => WaterIntake.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Bugünün su tüketimi getirme hatası: $e');
      return [];
    }
  }

  // Su tüketimi geçmişini getirme
  Future<List<WaterIntake>> getUserWaterHistory(String userId, {int days = 7}) async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(days: days));

      QuerySnapshot querySnapshot = await _firestore
          .collection('water_intake')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .where('timestamp', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => WaterIntake.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Su tüketimi geçmişi getirme hatası: $e');
      return [];
    }
  }

  // Su tüketimi silme
  Future<bool> deleteWaterIntake(String waterIntakeId) async {
    try {
      await _firestore
          .collection('water_intake')
          .doc(waterIntakeId)
          .delete();
      print('Su tüketimi silindi: $waterIntakeId');
      return true;
    } catch (e) {
      print('Su tüketimi silme hatası: $e');
      return false;
    }
  }

  // Uyku zamanını kaydetme ve günlük verileri arşivleme
  Future<bool> setSleepTime(String userId) async {
    try {
      final now = DateTime.now();
      
      // Kullanıcı profilini güncelle
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'lastSleepTime': Timestamp.fromDate(now),
        'lastResetDate': Timestamp.fromDate(now),
      });

      // Bugünkü verileri arşive taşı
      await _archiveTodaysData(userId, now);
      
      print('Uyku zamanı kaydedildi ve veriler arşivlendi');
      return true;
    } catch (e) {
      print('Uyku zamanı kaydetme hatası: $e');
      return false;
    }
  }

  // Uyanma zamanını kaydetme
  Future<bool> setWakeUpTime(String userId) async {
    try {
      final now = DateTime.now();
      
      // Önce mevcut uyku zamanını al
      final userDoc = await _firestore.collection('users').doc(userId).get();
      double? sleepDuration;
      
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final lastSleepTime = data['lastSleepTime'];
        
        if (lastSleepTime != null) {
          final sleepTime = (lastSleepTime as Timestamp).toDate();
          final duration = now.difference(sleepTime);
          sleepDuration = duration.inMinutes / 60.0; // Saat cinsinden
          print('Uyku süresi hesaplandı: ${sleepDuration.toStringAsFixed(1)} saat');
        }
      }
      
      // Kullanıcı profilini güncelle
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'lastSleepTime': null,
        'lastWakeUpTime': Timestamp.fromDate(now),
        'lastSleepDuration': sleepDuration,
      });
      
      print('Uyanma zamanı kaydedildi');
      return true;
    } catch (e) {
      print('Uyanma zamanı kaydetme hatası: $e');
      return false;
    }
  }

  // Bugünkü verileri arşive taşıma
  Future<void> _archiveTodaysData(String userId, DateTime sleepTime) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      // Bugünkü yemekleri arşiv koleksiyonuna kopyala
      final foodQuery = await _firestore
          .collection('food_items')
          .where('userId', isEqualTo: userId)
          .where('scannedAt', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('scannedAt', isLessThan: endOfDay.millisecondsSinceEpoch)
          .get();

      for (final doc in foodQuery.docs) {
        final data = doc.data();
        data['archivedAt'] = Timestamp.fromDate(sleepTime);
        data['originalDate'] = Timestamp.fromDate(startOfDay);
        
        await _firestore
            .collection('food_archive')
            .doc(doc.id)
            .set(data);
      }

      // Bugünkü su tüketimini arşiv koleksiyonuna kopyala
      final waterQuery = await _firestore
          .collection('water_intake')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('timestamp', isLessThan: endOfDay.millisecondsSinceEpoch)
          .get();

      for (final doc in waterQuery.docs) {
        final data = doc.data();
        data['archivedAt'] = Timestamp.fromDate(sleepTime);
        data['originalDate'] = Timestamp.fromDate(startOfDay);
        
        await _firestore
            .collection('water_archive')
            .doc(doc.id)
            .set(data);
      }

      print('Bugünkü veriler arşivlendi: ${foodQuery.docs.length} yemek, ${waterQuery.docs.length} su kaydı');
    } catch (e) {
      print('Veri arşivleme hatası: $e');
    }
  }

  // Günlük verileri sıfırlama (uyku sonrası)
  Future<bool> resetDailyData(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      // Bugünkü yemekleri sil
      final foodQuery = await _firestore
          .collection('food_items')
          .where('userId', isEqualTo: userId)
          .where('scannedAt', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('scannedAt', isLessThan: endOfDay.millisecondsSinceEpoch)
          .get();

      for (final doc in foodQuery.docs) {
        await doc.reference.delete();
      }

      // Bugünkü su tüketimini sil
      final waterQuery = await _firestore
          .collection('water_intake')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .where('timestamp', isLessThan: endOfDay.millisecondsSinceEpoch)
          .get();

      for (final doc in waterQuery.docs) {
        await doc.reference.delete();
      }

      print('Günlük veriler sıfırlandı: ${foodQuery.docs.length} yemek, ${waterQuery.docs.length} su kaydı silindi');
      return true;
    } catch (e) {
      print('Günlük veri sıfırlama hatası: $e');
      return false;
    }
  }

  // Arşivlenmiş verileri getirme (history_tab için)
  Future<List<FoodItem>> getArchivedFoodHistory(String userId) async {
    try {
      // Hem normal food_items hem de food_archive'den al
      final normalQuery = await _firestore
          .collection('food_items')
          .where('userId', isEqualTo: userId)
          .orderBy('scannedAt', descending: true)
          .get();

      final archiveQuery = await _firestore
          .collection('food_archive')
          .where('userId', isEqualTo: userId)
          .orderBy('scannedAt', descending: true)
          .get();

      List<FoodItem> allFoods = [];
      
      // Normal kayıtları ekle
      allFoods.addAll(normalQuery.docs
          .map((doc) => FoodItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList());
      
      // Arşiv kayıtlarını ekle
      allFoods.addAll(archiveQuery.docs
          .map((doc) => FoodItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList());

      // Tarihe göre sırala
      allFoods.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

      return allFoods;
    } catch (e) {
      print('Arşiv yemek geçmişi getirme hatası: $e');
      return [];
    }
  }

  // UYKU KAYITLARI FONKSİYONLARI

  // Uyku kaydı kaydetme
  Future<bool> saveSleepRecord(SleepRecord sleepRecord) async {
    return await _retryFirestoreOperation(
      () async {
        await _firestore
            .collection('sleep_records')
            .doc(sleepRecord.id)
            .set(sleepRecord.toMap());
        return true;
      },
      'Uyku kaydı kaydetme',
    ) ?? false;
  }

  // Kullanıcının uyku geçmişini getirme
  Future<List<SleepRecord>> getUserSleepHistory(String userId, {int limit = 30}) async {
    try {
      final query = await _firestore
          .collection('sleep_records')
          .where('userId', isEqualTo: userId)
          .orderBy('sleepTime', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => SleepRecord.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Uyku geçmişi getirme hatası: $e');
      return [];
    }
  }

  // Son uyku kaydını getirme
  Future<SleepRecord?> getLastSleepRecord(String userId) async {
    try {
      final query = await _firestore
          .collection('sleep_records')
          .where('userId', isEqualTo: userId)
          .orderBy('sleepTime', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return SleepRecord.fromMap(query.docs.first.data(), query.docs.first.id);
      }
      return null;
    } catch (e) {
      print('Son uyku kaydı getirme hatası: $e');
      return null;
    }
  }

  // Uyku kaydını güncelleme (uyanma zamanı vs.)
  Future<bool> updateSleepRecord(String sleepRecordId, Map<String, dynamic> updates) async {
    return await _retryFirestoreOperation(
      () async {
        await _firestore
            .collection('sleep_records')
            .doc(sleepRecordId)
            .update(updates);
        return true;
      },
      'Uyku kaydı güncelleme',
    ) ?? false;
  }

  // Uyku istatistikleri hesaplama
  Future<Map<String, dynamic>> getSleepStatistics(String userId, {int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final query = await _firestore
          .collection('sleep_records')
          .where('userId', isEqualTo: userId)
          .where('sleepTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('sleepTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final records = query.docs
          .map((doc) => SleepRecord.fromMap(doc.data(), doc.id))
          .where((record) => record.duration != null)
          .toList();

      if (records.isEmpty) {
        return {
          'averageDuration': 0.0,
          'totalSleepTime': 0.0,
          'recordCount': 0,
          'qualityDistribution': <String, int>{},
        };
      }

      final durations = records.map((r) => r.duration!).toList();
      final averageDuration = durations.reduce((a, b) => a + b) / durations.length;
      final totalSleepTime = durations.reduce((a, b) => a + b);

      // Kalite dağılımı
      Map<String, int> qualityDistribution = {};
      for (final record in records) {
        qualityDistribution[record.quality] = (qualityDistribution[record.quality] ?? 0) + 1;
      }

      return {
        'averageDuration': averageDuration,
        'totalSleepTime': totalSleepTime,
        'recordCount': records.length,
        'qualityDistribution': qualityDistribution,
        'records': records,
      };
    } catch (e) {
      print('Uyku istatistikleri hesaplama hatası: $e');
      return {
        'averageDuration': 0.0,
        'totalSleepTime': 0.0,
        'recordCount': 0,
        'qualityDistribution': <String, int>{},
      };
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