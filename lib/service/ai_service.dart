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
      // Basit öneriler için fallback kullan
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
Günlük beslenme verilerini analiz et ve SADECE geçerli JSON formatında yanıt ver:

Bugünkü yemekler: ${todaysFoods.map((f) => '${f.name}: ${f.calories} kcal, P:${f.protein}g, C:${f.carbs}g, F:${f.fat}g').join(' | ')}

SADECE bu JSON formatını kullan, başka hiçbir metin ekleme:

{
  "total_calories": ${todaysFoods.fold(0, (sum, f) => sum + f.calories)},
  "total_protein": ${todaysFoods.fold(0.0, (sum, f) => sum + f.protein)},
  "total_carbs": ${todaysFoods.fold(0.0, (sum, f) => sum + f.carbs)},
  "total_fat": ${todaysFoods.fold(0.0, (sum, f) => sum + f.fat)},
  "nutrition_score": 75,
  "balance_analysis": "Günlük beslenme analizi",
  "macro_percentages": {
    "protein": 20,
    "carbs": 50,
    "fat": 30
  },
  "recommendations": [
    "Su tüketimini artırın",
    "Sebze oranını artırın",
    "Düzenli öğün saatlerine dikkat edin"
  ],
  "warnings": null,
  "achievements": ["Beslenme takibine devam ediyorsunuz"],
  "tomorrow_focus": "Protein dengesi"
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        String cleanText = response.text!.trim();
        
        // Markdown temizleme
        cleanText = cleanText.replaceAll('```json', '');
        cleanText = cleanText.replaceAll('```', '');
        cleanText = cleanText.replaceAll('**Açıklamalar:**', '');
        cleanText = cleanText.replaceAll('**', '');
        
        // Sadece JSON kısmını al
        final jsonStart = cleanText.indexOf('{');
        final jsonEnd = cleanText.lastIndexOf('}');
        
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          cleanText = cleanText.substring(jsonStart, jsonEnd + 1);
        }
        
        // JSON parse et
        try {
          final result = jsonDecode(cleanText);
          if (result is Map<String, dynamic>) {
            return result;
          }
        } catch (jsonError) {
          print('JSON parse hatası: $jsonError');
          print('Temizlenmiş text: $cleanText');
        }
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
    
    if (remainingCalories > 400) {
      return [
        {
          'title': 'Izgara Tavuk Salata',
          'description': 'Yüksek protein, düşük kalori içeriği ile ideal ana öğün seçenek',
          'type': 'nutrition',
          'importance': 'high'
        },
        {
          'title': 'Sebze Çorbası',
          'description': 'Vitamin ve mineral açısından zengin, doyurucu bir seçenek',
          'type': 'nutrition',
          'importance': 'medium'
        },
        {
          'title': 'Su İçmeyi Unutmayın',
          'description': 'Günde en az 8 bardak su için',
          'type': 'hydration',
          'importance': 'high'
        }
      ];
    } else if (remainingCalories > 150) {
      return [
        {
          'title': 'Yoğurt ve Meyve',
          'description': 'Probiyotik ve doğal şeker kaynağı olan hafif atıştırmalık',
          'type': 'nutrition',
          'importance': 'medium'
        },
        {
          'title': 'Badem veya Ceviz',
          'description': 'Sağlıklı yağlar ve protein için ideal',
          'type': 'nutrition',
          'importance': 'medium'
        }
      ];
    } else if (remainingCalories > 0) {
      return [
        {
          'title': 'Yeşil Çay',
          'description': 'Antioksidan kaynağı, metabolizmayı destekler',
          'type': 'hydration',
          'importance': 'low'
        },
        {
          'title': 'Meyve Suyu (Taze)',
          'description': 'Vitamin C ve doğal şeker kaynağı',
          'type': 'hydration',
          'importance': 'low'
        }
      ];
    } else {
      return [
        {
          'title': 'Kalori Hedefine Ulaştınız',
          'description': 'Bugünlük yeterli kalori aldınız. Su içmeye devam edin.',
          'type': 'general',
          'importance': 'medium'
        },
        {
          'title': 'Hafif Yürüyüş',
          'description': 'Sindirim için 10-15 dakika hafif yürüyüş yapabilirsiniz',
          'type': 'exercise',
          'importance': 'low'
        }
      ];
    }
  }

  Map<String, dynamic> _getFallbackNutritionAnalysis(List<FoodItem> todaysFoods) {
    double totalCalories = todaysFoods.fold(0.0, (sum, food) => sum + food.calories);
    double totalProtein = todaysFoods.fold(0.0, (sum, food) => sum + food.protein);
    double totalCarbs = todaysFoods.fold(0.0, (sum, food) => sum + food.carbs);
    double totalFat = todaysFoods.fold(0.0, (sum, food) => sum + food.fat);

    // Beslenme skoru hesaplama
    int nutritionScore = 50;
    if (totalCalories > 1500 && totalCalories < 2500) nutritionScore += 20;
    if (totalProtein > 50) nutritionScore += 15;
    if (totalCarbs > 100) nutritionScore += 10;
    if (totalFat > 30) nutritionScore += 5;
    
    // Makro yüzdeleri hesaplama
    double proteinPercent = totalCalories > 0 ? (totalProtein * 4 / totalCalories * 100) : 0;
    double carbsPercent = totalCalories > 0 ? (totalCarbs * 4 / totalCalories * 100) : 0;
    double fatPercent = totalCalories > 0 ? (totalFat * 9 / totalCalories * 100) : 0;

    // Dinamik öneriler
    List<String> recommendations = [];
    if (totalCalories < 1200) {
      recommendations.add('Kalori alımınızı artırmalısınız');
    }
    if (proteinPercent < 15) {
      recommendations.add('Protein tüketimini artırın');
    }
    if (carbsPercent > 60) {
      recommendations.add('Karbonhidrat oranını azaltın');
    }
    recommendations.addAll([
      'Günde en az 8 bardak su için',
      'Sebze ve meyve tüketimini artırın',
      'Düzenli öğün saatlerine dikkat edin'
    ]);

    // Başarılar
    List<String> achievements = [];
    if (todaysFoods.isNotEmpty) {
      achievements.add('Beslenme takibine devam ediyorsunuz!');
    }
    if (totalCalories > 1000) {
      achievements.add('Günlük kalori hedefine yaklaşıyorsunuz');
    }
    if (proteinPercent >= 15) {
      achievements.add('Protein dengeniz iyi');
    }

    return {
      'total_calories': totalCalories.round(),
      'total_protein': totalProtein.round(),
      'total_carbs': totalCarbs.round(),
      'total_fat': totalFat.round(),
      'nutrition_score': nutritionScore.clamp(0, 100),
      'balance_analysis': todaysFoods.isEmpty 
          ? 'Henüz yemek kaydı yok. İlk yemeğinizi ekleyerek başlayın!'
          : 'Günlük beslenme dengeniz değerlendiriliyor. Protein: %${proteinPercent.toInt()}, Karbonhidrat: %${carbsPercent.toInt()}, Yağ: %${fatPercent.toInt()}',
      'macro_percentages': {
        'protein': proteinPercent.round(),
        'carbs': carbsPercent.round(),
        'fat': fatPercent.round(),
      },
      'recommendations': recommendations,
      'warnings': totalCalories > 3000 ? ['Günlük kalori alımınız yüksek'] : null,
      'achievements': achievements,
      'tomorrow_focus': proteinPercent < 15 ? 'Protein dengesi' : 'Sebze ve meyve tüketimi'
    };
  }
} 