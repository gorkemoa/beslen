import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../models/water_intake.dart';
import '../service/firebase_service.dart';
import '../service/ai_service.dart';

class AppViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final AIService _aiService = AIService();

  UserProfile? _userProfile;
  List<FoodItem> _foodHistory = [];
  List<FoodItem> _todaysFoods = [];
  List<WaterIntake> _todaysWaterIntake = [];
  List<WaterIntake> _waterHistory = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  UserProfile? get userProfile => _userProfile;
  List<FoodItem> get foodHistory => _foodHistory;
  List<FoodItem> get todaysFoods => _todaysFoods;
  List<WaterIntake> get todaysWaterIntake => _todaysWaterIntake;
  List<WaterIntake> get waterHistory => _waterHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _userProfile != null;
  FirebaseService get firebaseService => _firebaseService;

  // Anonim giriş yapma
  Future<bool> signInAnonymously() async {
    _setLoading(true);
    try {
      // Önce mevcut kullanıcıyı kontrol et
      if (_firebaseService.currentUser != null) {
        print('Mevcut kullanıcı bulundu, profil yükleniyor...');
        await loadUserProfile();
        return true;
      }
      
      final userCredential = await _firebaseService.signInAnonymously();
      if (userCredential != null) {
        print('Yeni anonim kullanıcı oluşturuldu, profil yükleniyor...');
        await loadUserProfile();
        return true;
      } else {
        _setError('Firebase Authentication başarısız. Lütfen internet bağlantınızı kontrol edin.');
        return false;
      }
    } catch (e) {
      _setError('Giriş yapılırken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // E-posta ile giriş yapma
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      final userCredential = await _firebaseService.signInWithEmail(email, password);
      if (userCredential != null) {
        await loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _setError('E-posta giriş hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // E-posta ile kayıt yapma
  Future<bool> signUpWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      final userCredential = await _firebaseService.signUpWithEmail(email, password);
      if (userCredential != null) {
        await loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _setError('E-posta kayıt hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Google ile giriş yapma
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final userCredential = await _firebaseService.signInWithGoogle();
      if (userCredential != null) {
        await loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Google giriş hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Apple ile giriş yapma
  Future<bool> signInWithApple() async {
    _setLoading(true);
    try {
      final userCredential = await _firebaseService.signInWithApple();
      if (userCredential != null) {
        await loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Apple giriş hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Şifre sıfırlama
  Future<bool> resetPassword(String email) async {
    try {
      return await _firebaseService.resetPassword(email);
    } catch (e) {
      _setError('Şifre sıfırlama hatası: $e');
      return false;
    }
  }

  // Çıkış yapma
  Future<void> signOut() async {
    try {
      print('AppViewModel: Çıkış yapılıyor...');
      await _firebaseService.signOut();
      
      // Kullanıcı verilerini temizle
      _userProfile = null;
      _foodHistory.clear();
      _todaysFoods.clear();
      _todaysWaterIntake.clear();
      _waterHistory.clear();
      _error = null;
      
      print('AppViewModel: Kullanıcı verileri temizlendi');
      notifyListeners();
    } catch (e) {
      print('AppViewModel: Çıkış yapma hatası: $e');
      
      // Firebase çıkışı başarısız olsa bile kullanıcı verilerini temizle
      _userProfile = null;
      _foodHistory.clear();
      _todaysFoods.clear();
      _todaysWaterIntake.clear();
      _waterHistory.clear();
      
      // Hata mesajını set et ama throw etme, çıkış işlemi devam etsin
      _setError('Çıkış sırasında bir hata oluştu, ancak yerel veriler temizlendi.');
      notifyListeners();
    }
  }

  // Kullanıcı profili yükleme
  Future<void> loadUserProfile() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      print('Kullanıcı profili yükleniyor: ${user.uid}');
      
      try {
        final profile = await _firebaseService.getUserProfile(user.uid);
        _userProfile = profile;
        notifyListeners();
        
        if (profile != null) {
          print('Profil başarıyla yüklendi: ${profile.name}');
          await loadTodaysFoods();
          await loadFoodHistory();
        } else {
          print('Profil bulunamadı, yeni kullanıcı olabilir');
        }
      } catch (e) {
        print('Profil yükleme sırasında hata: $e');
        _setError('Profil yüklenemedi. İnternet bağlantınızı kontrol edin.');
      }
    } else {
      print('Aktif kullanıcı bulunamadı');
    }
  }

  // Kullanıcı profili kaydetme
  Future<bool> saveUserProfile(UserProfile profile) async {
    _setLoading(true);
    try {
      final success = await _firebaseService.saveUserProfile(profile);
      if (success) {
        _userProfile = profile;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Profil kaydedilirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Bugünün yemeklerini yükleme
  Future<void> loadTodaysFoods() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      _todaysFoods = await _firebaseService.getTodaysFoodItems(user.uid);
      notifyListeners();
    }
  }

  // Yemek geçmişini yükleme
  Future<void> loadFoodHistory() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      _foodHistory = await _firebaseService.getUserFoodHistory(user.uid);
      notifyListeners();
    }
  }

  // Yemek öğesi kaydetme
  Future<bool> saveFoodItem(FoodItem foodItem) async {
    _setLoading(true);
    try {
      final success = await _firebaseService.saveFoodItem(foodItem);
      if (success) {
        _todaysFoods.insert(0, foodItem);
        _foodHistory.insert(0, foodItem);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Yemek kaydedilirken hata oluştu: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Günlük beslenme analizini getir
  Future<Map<String, dynamic>> getDailyNutritionAnalysis() async {
    Map<String, dynamic>? profileData;
    if (_userProfile != null) {
      profileData = {
        'age': _userProfile!.age,
        'weight': _userProfile!.weight,
        'height': _userProfile!.height,
        'activityLevel': _userProfile!.activityLevel.toString(),
        'goal': _userProfile!.goal.toString(),
        'dailyCalorieNeeds': _userProfile!.dailyCalorieNeeds,
      };
    }
    
    return await _aiService.analyzeNutritionalBalance(_todaysFoods, profileData);
  }

  // Yemek önerilerini getir
  Future<List<Map<String, dynamic>>> getFoodRecommendations() async {
    if (_userProfile == null) return [];
    
    Map<String, dynamic> profileData = {
      'age': _userProfile!.age,
      'weight': _userProfile!.weight,
      'height': _userProfile!.height,
      'activityLevel': _userProfile!.activityLevel.toString(),
      'goal': _userProfile!.goal.toString(),
      'dailyCalorieNeeds': _userProfile!.dailyCalorieNeeds,
    };
    
    return await _aiService.generateSmartRecommendations(
      _todaysFoods,
      _userProfile!.dailyCalorieNeeds,
      profileData,
    );
  }

  // Bugünün kalori toplamı
  int get todaysCalories {
    return _todaysFoods.fold(0, (sum, food) => sum + food.calories);
  }

  // Bugünün protein toplamı
  double get todaysProtein {
    return _todaysFoods.fold(0.0, (sum, food) => sum + food.protein);
  }

  // Bugünün karbonhidrat toplamı
  double get todaysCarbs {
    return _todaysFoods.fold(0.0, (sum, food) => sum + food.carbs);
  }

  // Bugünün yağ toplamı
  double get todaysFat {
    return _todaysFoods.fold(0.0, (sum, food) => sum + food.fat);
  }

  // Kalori hedefine göre yüzde
  double get caloriePercentage {
    if (_userProfile == null) return 0.0;
    return (todaysCalories / _userProfile!.dailyCalorieNeeds).clamp(0.0, 1.0);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 