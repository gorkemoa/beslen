import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/food_item.dart';

class GeminiAIService {
  late final GenerativeModel _model;
  static const String _apiKey = 'YOUR_GEMINI_API_KEY'; // Bu değer .env dosyasından gelecek

  GeminiAIService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
    );
  }

  Future<FoodAnalysisResult> analyzeFoodImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      final prompt = '''
      Bu görseldeki yemeği analiz et ve aşağıdaki bilgileri JSON formatında ver:
      
      {
        "name": "yemeğin adı",
        "description": "yemeğin kısa açıklaması",
        "calories": 100 gram başına kalori miktarı (sayı),
        "protein": 100 gram başına protein miktarı gram cinsinden (sayı),
        "carbohydrates": 100 gram başına karbonhidrat miktarı gram cinsinden (sayı),
        "fat": 100 gram başına yağ miktarı gram cinsinden (sayı),
        "fiber": 100 gram başına lif miktarı gram cinsinden (sayı),
        "estimatedPortion": tahmin edilen porsiyon miktarı gram cinsinden (sayı),
        "confidence": tahmin güvenilirlik skoru 0-1 arası (sayı)
      }
      
      Eğer görsel yemek değilse veya tanımlanamazsa, confidence değerini 0 yap.
      Sadece JSON yanıtı ver, başka açıklama ekleme.
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text ?? '';
      
      return _parseAnalysisResult(responseText);
    } catch (e) {
      throw Exception('Görsel analizi sırasında hata: $e');
    }
  }

  Future<List<String>> getDailyRecommendations(List<FoodItem> recentFoods, double targetCalories) async {
    try {
      final recentFoodsText = recentFoods.map((food) => food.name).join(', ');
      
      final prompt = '''
      Kullanıcının son zamanlarda tükettiği yemekler: $recentFoodsText
      Günlük hedef kalori: $targetCalories
      
      Bu bilgilere dayanarak kullanıcıya 5 sağlıklı beslenme önerisi ver.
      Her öneriyi ayrı satırda listele, madde işareti kullanma.
      Öneriler Türkçe olmalı ve pratik uygulanabilir olmalı.
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';
      
      return responseText
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(5)
          .toList();
    } catch (e) {
      return [
        'Günde en az 5 porsiyon sebze ve meyve tüketin',
        'Bol su için, günde en az 8 bardak su içmeye çalışın',
        'Öğün aralarında sağlıklı atıştırmalıklar tercih edin',
        'Porsiyon miktarlarınıza dikkat edin',
        'Düzenli öğün saatlerine uyun'
      ];
    }
  }

  FoodAnalysisResult _parseAnalysisResult(String responseText) {
    try {
      // JSON parsing burada yapılacak
      // Şimdilik basit bir örnek dönüyoruz
      return FoodAnalysisResult(
        name: 'Tanınmayan Yemek',
        description: 'Görsel analiz edilemedi',
        calories: 0,
        protein: 0,
        carbohydrates: 0,
        fat: 0,
        fiber: 0,
        estimatedPortion: 100,
        confidence: 0,
      );
    } catch (e) {
      throw Exception('Analiz sonucu ayrıştırılamadı: $e');
    }
  }
}

class FoodAnalysisResult {
  final String name;
  final String description;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double estimatedPortion;
  final double confidence;

  FoodAnalysisResult({
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.estimatedPortion,
    required this.confidence,
  });

  bool get isValid => confidence > 0.5;
} 