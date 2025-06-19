import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../models/daily_summary.dart';
import '../service/firebase_service.dart';
import '../service/gemini_ai_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final GeminiAIService _aiService = GeminiAIService();

  bool _isLoading = false;
  String? _error;
  UserProfile? _userProfile;
  List<FoodItem> _todaysFoods = [];
  DailySummary? _todaySummary;

  // Stream subscriptions for cleanup
  StreamSubscription<UserProfile?>? _userProfileSubscription;
  StreamSubscription<List<FoodItem>>? _foodItemsSubscription;

  bool get isLoading => _isLoading;
  String? get error => _error;
  UserProfile? get userProfile => _userProfile;
  List<FoodItem> get todaysFoods => _todaysFoods;
  DailySummary? get todaySummary => _todaySummary;

  double get totalCalories => _todaysFoods.fold(
    0.0, 
    (sum, food) => sum + food.nutritionInfo.calories
  );

  double get totalProtein => _todaysFoods.fold(
    0.0, 
    (sum, food) => sum + food.nutritionInfo.protein
  );

  double get totalCarbs => _todaysFoods.fold(
    0.0, 
    (sum, food) => sum + food.nutritionInfo.carbohydrates
  );

  double get totalFat => _todaysFoods.fold(
    0.0, 
    (sum, food) => sum + food.nutritionInfo.fat
  );

  double get calorieGoal => _userProfile?.dailyCalorieGoal ?? 2000.0;
  double get remainingCalories => calorieGoal - totalCalories;
  double get calorieProgress => (totalCalories / calorieGoal).clamp(0.0, 1.0);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadUserProfile();
      await loadTodaysFoods();
      _setupFoodItemsStream(); // Real-time updates için stream kurulumu
      await generateDailySummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupUserProfileStream() {
    _userProfileSubscription?.cancel();
    _userProfileSubscription = _firebaseService.getUserProfileStream(_firebaseService.userId).listen(
      (profile) {
        _userProfile = profile;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Profil yüklenemedi: $error';
        notifyListeners();
      },
    );
  }

  Future<void> loadUserProfile() async {
    try {
      _userProfile = await _firebaseService.getUserProfile(_firebaseService.userId);
      _setupUserProfileStream(); // Real-time updates için stream kurulumu
      notifyListeners();
    } catch (e) {
      _error = 'Profil yüklenemedi: $e';
      notifyListeners();
    }
  }

  void _setupFoodItemsStream() {
    _foodItemsSubscription?.cancel();
    _foodItemsSubscription = _firebaseService.getTodaysFoodItemsStream(_firebaseService.userId).listen(
      (foods) {
        _todaysFoods = foods;
        generateDailySummary();
      },
      onError: (error) {
        _error = 'Günlük yemekler yüklenemedi: $error';
        notifyListeners();
      },
    );
  }

  Future<void> loadTodaysFoods() async {
    try {
      _todaysFoods = await _firebaseService.getTodaysFoodItems(_firebaseService.userId);
      notifyListeners();
    } catch (e) {
      _error = 'Günlük yemekler yüklenemedi: $e';
      notifyListeners();
    }
  }

  Future<void> generateDailySummary() async {
    if (_userProfile == null) return;

    final totalNutrition = _calculateTotalNutrition();
    
    _todaySummary = DailySummary(
      id: DateTime.now().toIso8601String().split('T')[0],
      userId: _firebaseService.userId,
      date: DateTime.now(),
      consumedFoods: _todaysFoods,
      totalNutrition: totalNutrition,
      calorieGoal: _userProfile!.dailyCalorieGoal,
    );

    try {
      await _firebaseService.saveDailySummary(_todaySummary!);
    } catch (e) {
      print('Günlük özet kaydedilemedi: $e');
    }
    
    notifyListeners();
  }

  NutritionInfo _calculateTotalNutrition() {
    return _todaysFoods.fold(
      NutritionInfo(calories: 0, protein: 0, carbohydrates: 0, fat: 0),
      (total, food) => NutritionInfo(
        calories: total.calories + food.nutritionInfo.calories,
        protein: total.protein + food.nutritionInfo.protein,
        carbohydrates: total.carbohydrates + food.nutritionInfo.carbohydrates,
        fat: total.fat + food.nutritionInfo.fat,
        fiber: total.fiber + food.nutritionInfo.fiber,
        sugar: total.sugar + food.nutritionInfo.sugar,
        sodium: total.sodium + food.nutritionInfo.sodium,
        calcium: total.calcium + food.nutritionInfo.calcium,
        iron: total.iron + food.nutritionInfo.iron,
        vitaminC: total.vitaminC + food.nutritionInfo.vitaminC,
        vitaminA: total.vitaminA + food.nutritionInfo.vitaminA,
      ),
    );
  }

  Future<void> deleteFoodItem(String foodId) async {
    try {
      await _firebaseService.deleteFoodItem(foodId, _firebaseService.userId);
      await loadTodaysFoods();
      await generateDailySummary();
    } catch (e) {
      _error = 'Yemek silinemedi: $e';
      notifyListeners();
    }
  }

  Future<String> getMealRecommendation() async {
    if (_userProfile == null) return 'Öneri üretilemedi';
    
    try {
      return await _aiService.generateMealRecommendation(
        remainingCalories,
        _userProfile!.allergies,
        _userProfile!.dietaryRestrictions,
      );
    } catch (e) {
      return 'Öneri üretilemedi: $e';
    }
  }

  List<String> getAllergenWarnings(FoodItem food) {
    if (_userProfile == null) return [];
    return _userProfile!.checkAllergens(food.allergens);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refreshData() {
    initialize();
  }

  @override
  void dispose() {
    _userProfileSubscription?.cancel();
    _foodItemsSubscription?.cancel();
    super.dispose();
  }
} 