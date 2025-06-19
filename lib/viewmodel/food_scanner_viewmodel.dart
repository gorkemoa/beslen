import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../service/firebase_service.dart';
import '../service/gemini_ai_service.dart';
import '../service/camera_service.dart';

class FoodScannerViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final GeminiAIService _aiService = GeminiAIService();
  final CameraService _cameraService = CameraService();

  File? _selectedImage;
  FoodAnalysisResult? _analysisResult;
  FoodItem? _analyzedFood;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _error;

  // Getters
  File? get selectedImage => _selectedImage;
  FoodAnalysisResult? get analysisResult => _analysisResult;
  FoodItem? get analyzedFood => _analyzedFood;
  bool get isAnalyzing => _isAnalyzing;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get hasValidAnalysis => _analysisResult?.isValid ?? false;

  Future<void> pickImageFromCamera() async {
    _clearError();
    
    try {
      final image = await _cameraService.pickImageFromCamera();
      if (image != null) {
        _selectedImage = image;
        notifyListeners();
        await _analyzeImage();
      }
    } catch (e) {
      _setError('Kamera kullanılamadı: $e');
    }
  }

  Future<void> pickImageFromGallery() async {
    _clearError();
    
    try {
      final image = await _cameraService.pickImageFromGallery();
      if (image != null) {
        _selectedImage = image;
        notifyListeners();
        await _analyzeImage();
      }
    } catch (e) {
      _setError('Galeri kullanılamadı: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    _setAnalyzing(true);
    _clearError();

    try {
      _analysisResult = await _aiService.analyzeFoodImage(_selectedImage!);
      
      if (_analysisResult!.isValid) {
        await _createFoodItem();
      } else {
        _setError('Yemek tanınamadı. Lütfen başka bir fotoğraf deneyin.');
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Analiz sırasında hata oluştu: $e');
    } finally {
      _setAnalyzing(false);
    }
  }

  Future<void> _createFoodItem() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null || _analysisResult == null) return;

    try {
      // Firebase Storage'a görsel yükle
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _firebaseService.uploadFoodImage(_selectedImage!, userId);
      }

      // FoodItem oluştur
      _analyzedFood = FoodItem(
        id: '', // Firebase'den gelecek
        name: _analysisResult!.name,
        description: _analysisResult!.description,
        calories: _analysisResult!.calories,
        protein: _analysisResult!.protein,
        carbohydrates: _analysisResult!.carbohydrates,
        fat: _analysisResult!.fat,
        fiber: _analysisResult!.fiber,
        imageUrl: imageUrl,
        userId: userId,
        scannedAt: DateTime.now(),
        portion: _analysisResult!.estimatedPortion,
      );

      notifyListeners();
    } catch (e) {
      _setError('Yemek verisi hazırlanamadı: $e');
    }
  }

  Future<bool> saveFoodItem() async {
    if (_analyzedFood == null) return false;

    _setSaving(true);
    _clearError();

    try {
      final foodId = await _firebaseService.saveFoodItem(_analyzedFood!);
      _analyzedFood = _analyzedFood!.copyWith();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Yemek kaydedilemedi: $e');
      return false;
    } finally {
      _setSaving(false);
    }
  }

  void updatePortion(double newPortion) {
    if (_analyzedFood != null) {
      _analyzedFood = _analyzedFood!.copyWith(portion: newPortion);
      notifyListeners();
    }
  }

  void updateFoodDetails({
    String? name,
    String? description,
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat,
    double? fiber,
  }) {
    if (_analyzedFood != null) {
      _analyzedFood = _analyzedFood!.copyWith(
        name: name,
        description: description,
        calories: calories,
        protein: protein,
        carbohydrates: carbohydrates,
        fat: fat,
        fiber: fiber,
      );
      notifyListeners();
    }
  }

  void clearData() {
    _selectedImage = null;
    _analysisResult = null;
    _analyzedFood = null;
    _clearError();
    notifyListeners();
  }

  void _setAnalyzing(bool analyzing) {
    _isAnalyzing = analyzing;
    notifyListeners();
  }

  void _setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
} 