import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/food_item.dart';

class AIService {
  // Gemini AI API anahtarı - Gerçek uygulamada environment variable kullanın
  static const String _apiKey = 'AIzaSyB53XGwpaQ25hPyLlBja4wu_ZcjP33IrHQ'; // Buraya gerçek API anahtarınızı yazın
  
  late final GenerativeModel _model;
  
  AIService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        topK: 32,
        topP: 1,
        maxOutputTokens: 4096,
      ),
    );
  }

  Future<Map<String, dynamic>?> analyzeFoodImage(File imageFile) async {
    try {
      // Görüntüyü byte array olarak oku
      final bytes = await imageFile.readAsBytes();
      
      // Gemini AI'ya gönderilecek prompt
      const String prompt = '''
Bu görüntüdeki yemeği analiz et ve aşağıdaki JSON formatında besin değerlerini hesapla:

{
  "name": "Yemeğin Türkçe adı",
  "calories": Kalori miktarı (sayı),
  "protein": Protein gram (ondalıklı sayı),
  "carbs": Karbonhidrat gram (ondalıklı sayı), 
  "fat": Yağ gram (ondalıklı sayı),
  "fiber": Lif gram (ondalıklı sayı),
  "sugar": Şeker gram (ondalıklı sayı),
  "sodium": Sodyum mg (ondalıklı sayı),
  "confidence": Güven skoru 0.0-1.0 arası,
  "portion_size": "Porsiyon büyüklüğü tahmini",
  "ingredients": ["malzeme1", "malzeme2", "malzeme3"],
  "cooking_method": "Pişirme yöntemi",
  "health_score": Sağlık skoru 1-10 arası,
  "warnings": ["Uyarı1", "Uyarı2"] veya null,
  "benefits": ["Fayda1", "Fayda2"]
}

Sadece JSON yanıtı ver, başka açıklama yapma. Türk mutfağını dikkate al.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        // JSON yanıtını parse et
        final cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final Map<String, dynamic> result = jsonDecode(cleanJson);
        
        // Sonucu validate et
        if (result['name'] != null && result['calories'] != null) {
          return result;
        }
      }
      
      return null;
    } catch (e) {
      print('Gemini AI analiz hatası: $e');
      return _getFallbackAnalysis();
    }
  }

  Future<List<Map<String, dynamic>>> generateSmartRecommendations(
    List<FoodItem> recentFoods,
    double targetCalories,
    Map<String, dynamic>? userProfile,
  ) async {
    try {
      final prompt = '''
Kullanıcının beslenme geçmişini ve hedeflerini analiz ederek kişiselleştirilmiş öneriler üret:

Son yemekler: ${recentFoods.map((f) => '${f.name}: ${f.calories} kcal').join(', ')}
Hedef kalori: $targetCalories
Kullanıcı profili: ${userProfile?.toString() ?? 'Bilinmiyor'}

Aşağıdaki JSON formatında 5 akıllı öneri ver:

{
  "recommendations": [
    {
      "name": "Yemek adı",
      "calories": Kalori,
      "protein": Protein gram,
      "carbs": Karbonhidrat gram,
      "fat": Yağ gram,
      "reason": "Neden öneriliyor (detaylı açıklama)",
      "type": "main/snack/drink",
      "priority": "high/medium/low",
      "preparation_time": "Hazırlama süresi",
      "difficulty": "kolay/orta/zor",
      "health_benefits": ["Fayda1", "Fayda2"],
      "recipe_tips": "Kısa tarif ipucu"
    }
  ],
  "daily_analysis": "Günlük beslenme analizi ve öneriler",
  "missing_nutrients": ["Eksik besin öğeleri"],
  "next_meal_suggestion": "Sonraki öğün önerisi"
}

Türk mutfağını ve sağlıklı beslenme prensiplerini dikkate al.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        final cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final result = jsonDecode(cleanJson);
        return List<Map<String, dynamic>>.from(result['recommendations'] ?? []);
      }
      
      return _getFallbackRecommendations(recentFoods, targetCalories);
    } catch (e) {
      print('Gemini AI öneri hatası: $e');
      return _getFallbackRecommendations(recentFoods, targetCalories);
    }
  }

  Future<Map<String, dynamic>> analyzeNutritionalBalance(
    List<FoodItem> todaysFoods,
    Map<String, dynamic>? userProfile,
  ) async {
    try {
      final prompt = '''
Günlük beslenme verilerini analiz et ve detaylı rapor hazırla:

Bugünkü yemekler: ${todaysFoods.map((f) => '${f.name}: ${f.calories} kcal, P:${f.protein}g, C:${f.carbs}g, F:${f.fat}g').join(' | ')}
Kullanıcı profili: ${userProfile?.toString() ?? 'Bilinmiyor'}

Aşağıdaki JSON formatında analiz ver:

{
  "total_calories": Toplam kalori,
  "total_protein": Toplam protein,
  "total_carbs": Toplam karbonhidrat,
  "total_fat": Toplam yağ,
  "nutrition_score": Beslenme skoru (0-100),
  "balance_analysis": "Beslenme dengesi analizi",
  "macro_percentages": {
    "protein": Protein yüzdesi,
    "carbs": Karbonhidrat yüzdesi,
    "fat": Yağ yüzdesi
  },
  "recommendations": [
    "Öneri 1",
    "Öneri 2",
    "Öneri 3"
  ],
  "warnings": ["Uyarı 1", "Uyarı 2"] veya null,
  "achievements": ["Başarı 1", "Başarı 2"],
  "tomorrow_focus": "Yarın odaklanılacak beslenme alanı"
}

Sağlık uzmanı perspektifinden yaklaş ve Türkçe yanıtla.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        final cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        return jsonDecode(cleanJson);
      }
      
      return _getFallbackNutritionAnalysis(todaysFoods);
    } catch (e) {
      print('Gemini AI beslenme analizi hatası: $e');
      return _getFallbackNutritionAnalysis(todaysFoods);
    }
  }

  // Hata durumunda fallback analiz
  Map<String, dynamic> _getFallbackAnalysis() {
    return {
      'name': 'Bilinmeyen Yemek',
      'calories': 200,
      'protein': 8.0,
      'carbs': 25.0,
      'fat': 6.0,
      'fiber': 3.0,
      'sugar': 5.0,
      'sodium': 300.0,
      'confidence': 0.5,
      'portion_size': 'Orta porsiyon',
      'ingredients': ['Tahmin edilemedi'],
      'cooking_method': 'Bilinmiyor',
      'health_score': 5,
      'warnings': ['AI analizi yapılamadı'],
      'benefits': ['Genel beslenme değeri']
    };
  }

  List<Map<String, dynamic>> _getFallbackRecommendations(List<FoodItem> recentFoods, double targetCalories) {
    double consumedCalories = recentFoods.fold(0.0, (sum, food) => sum + food.calories);
    double remainingCalories = targetCalories - consumedCalories;
    
    if (remainingCalories > 300) {
      return [
        {
          'name': 'Izgara Tavuk Salata',
          'calories': 280,
          'protein': 35.0,
          'carbs': 12.0,
          'fat': 8.0,
          'reason': 'Yüksek protein, düşük kalori içeriği ile ideal bir seçenek',
          'type': 'main',
          'priority': 'high'
        },
        {
          'name': 'Avokado Toast',
          'calories': 320,
          'protein': 12.0,
          'carbs': 28.0,
          'fat': 18.0,
          'reason': 'Sağlıklı yağlar ve kompleks karbonhidrat kaynağı',
          'type': 'main', 
          'priority': 'medium'
        }
      ];
    } else if (remainingCalories > 100) {
      return [
        {
          'name': 'Yoğurt ve Meyve',
          'calories': 120,
          'protein': 8.0,
          'carbs': 18.0,
          'fat': 2.0,
          'reason': 'Probiyotik ve doğal şeker kaynağı',
          'type': 'snack',
          'priority': 'high'
        }
      ];
    } else {
      return [
        {
          'name': 'Yeşil Çay',
          'calories': 2,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
          'reason': 'Antioksidan kaynağı, metabolizmayı hızlandırır',
          'type': 'drink',
          'priority': 'medium'
        }
      ];
    }
  }

  Map<String, dynamic> _getFallbackNutritionAnalysis(List<FoodItem> todaysFoods) {
    double totalCalories = todaysFoods.fold(0.0, (sum, food) => sum + food.calories);
    double totalProtein = todaysFoods.fold(0.0, (sum, food) => sum + food.protein);
    double totalCarbs = todaysFoods.fold(0.0, (sum, food) => sum + food.carbs);
    double totalFat = todaysFoods.fold(0.0, (sum, food) => sum + food.fat);

    return {
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'nutrition_score': 60,
      'balance_analysis': 'Günlük beslenme verileriniz analiz ediliyor.',
      'macro_percentages': {
        'protein': totalCalories > 0 ? (totalProtein * 4 / totalCalories * 100) : 0,
        'carbs': totalCalories > 0 ? (totalCarbs * 4 / totalCalories * 100) : 0,
        'fat': totalCalories > 0 ? (totalFat * 9 / totalCalories * 100) : 0,
      },
      'recommendations': [
        'Günde en az 8 bardak su için',
        'Sebze ve meyve tüketimini artırın',
        'Düzenli öğün saatlerine dikkat edin'
      ],
      'warnings': null,
      'achievements': ['Beslenme takibine devam ediyorsunuz!'],
      'tomorrow_focus': 'Protein dengesi'
    };
  }
} 