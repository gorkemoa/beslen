import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../service/camera_service.dart';
import '../service/gemini_ai_service.dart';
import '../service/firebase_service.dart';

class FoodScannerViewModel extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final GeminiAIService _aiService = GeminiAIService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _error;
  FoodItem? _analyzedFood;
  File? _capturedImage;
  UserProfile? _userProfile;

  bool get isLoading => _isLoading;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;
  FoodItem? get analyzedFood => _analyzedFood;
  File? get capturedImage => _capturedImage;
  UserProfile? get userProfile => _userProfile;

  Future<void> loadUserProfile() async {
    try {
      _userProfile = await _firebaseService.getUserProfile(_firebaseService.userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> takeFoodPhoto() async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final image = await _cameraService.takeFoodPhoto();
      if (image != null) {
        _capturedImage = image;
        await _analyzeFoodImage(image);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickImageFromGallery() async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final image = await _cameraService.pickImageFromGallery();
      if (image != null) {
        _capturedImage = image;
        await _analyzeFoodImage(image);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _analyzeFoodImage(File imageFile) async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      final analyzedFood = await _aiService.analyzeFoodImage(imageFile);
      if (analyzedFood != null) {
        _analyzedFood = analyzedFood;
        
        // Alerji kontrolü yap
        if (_userProfile != null && _userProfile!.allergies.isNotEmpty) {
          final allergenWarnings = _userProfile!.checkAllergens(analyzedFood.allergens);
          if (allergenWarnings.isNotEmpty) {
            _error = 'UYARI: Bu yemekte şu alerjik maddeler bulunabilir: ${allergenWarnings.join(', ')}';
          }
        }
      } else {
        _error = 'Yemek analiz edilemedi. Lütfen tekrar deneyin veya daha net bir fotoğraf çekin.';
      }
    } catch (e) {
      _error = e.toString();
      _analyzedFood = null;
      _capturedImage = null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> saveFoodItem() async {
    if (_analyzedFood == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Önce resmi Firebase Storage'a yükle
      if (_capturedImage != null) {
        final imageUrl = await _firebaseService.uploadFoodImage(
          _capturedImage!,
          _firebaseService.userId,
        );
        
        // FoodItem'ı güncellenmiş image URL ile kaydet
        final updatedFood = _analyzedFood!.copyWith(imageUrl: imageUrl);
        await _firebaseService.saveFoodItem(updatedFood, _firebaseService.userId);
        
        _analyzedFood = updatedFood;
      } else {
        await _firebaseService.saveFoodItem(_analyzedFood!, _firebaseService.userId);
      }
      
      // Başarılı kayıt sonrası temizle
      _clearAnalysis();
    } catch (e) {
      _error = 'Yemek kaydedilemedi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateFoodItem(FoodItem updatedFood) {
    _analyzedFood = updatedFood;
    notifyListeners();
  }

  void updatePortionSize(double newSize) {
    if (_analyzedFood != null) {
      final multiplier = newSize / _analyzedFood!.portionSize;
      _analyzedFood = _analyzedFood!.copyWith(
        portionSize: newSize,
        nutritionInfo: _analyzedFood!.nutritionInfo * multiplier,
      );
      notifyListeners();
    }
  }

  void updateFoodName(String newName) {
    if (_analyzedFood != null) {
      _analyzedFood = _analyzedFood!.copyWith(name: newName);
      notifyListeners();
    }
  }

  void _clearError() {
    _error = null;
  }

  void _clearAnalysis() {
    _analyzedFood = null;
    _capturedImage = null;
    _error = null;
  }

  void clearAll() {
    _clearAnalysis();
    notifyListeners();
  }

  Future<List<String>> getSimilarFoodSuggestions() async {
    if (_analyzedFood == null) return [];
    
    try {
      return await _aiService.suggestSimilarFoods(_analyzedFood!.name);
    } catch (e) {
      print('Benzer yemek önerileri alınamadı: $e');
      return [];
    }
  }

  List<String> getAllergenWarnings() {
    if (_userProfile == null || _analyzedFood == null) return [];
    return _userProfile!.checkAllergens(_analyzedFood!.allergens);
  }

  bool hasAllergenWarnings() {
    return getAllergenWarnings().isNotEmpty;
  }
} 