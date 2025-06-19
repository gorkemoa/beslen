import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/food_item.dart';

class GeminiAIService {
  late final GenerativeModel _model;

  GeminiAIService() {
    // Environment variable'dan API key al
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY environment variable bulunamadı. Lütfen API key\'inizi tanımlayın.');
    }
    
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );
  }

  Future<FoodItem?> analyzeFoodImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      final prompt = '''
      Bu görüntüdeki yemeği analiz et ve aşağıdaki JSON formatında detaylı besin bilgilerini ver:

      {
        "name": "Yemeğin adı",
        "description": "Yemeğin kısa açıklaması",
        "nutritionInfo": {
          "calories": 0.0,
          "protein": 0.0,
          "carbohydrates": 0.0,
          "fat": 0.0,
          "fiber": 0.0,
          "sugar": 0.0,
          "sodium": 0.0,
          "calcium": 0.0,
          "iron": 0.0,
          "vitaminC": 0.0,
          "vitaminA": 0.0
        },
        "ingredients": ["malzeme1", "malzeme2"],
        "allergens": ["alerjen1", "alerjen2"],
        "portionSize": 1.0,
        "portionUnit": "porsiyon"
      }

      Önemli notlar:
      - Türkçe yemek adları kullan
      - Besin değerleri 100g için olsun
      - Yaygın alerjenleri listele (gluten, süt, yumurta, fındık, soya, balık, kabuklu deniz ürünleri, susam)
      - Sadece JSON formatında yanıt ver, başka açıklama ekleme
      - Eğer görüntüde yemek yoksa veya analiz edilemiyorsa boş JSON döndür: {}
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      if (responseText.isEmpty) {
        throw Exception('AI servisinden boş yanıt alındı');
      }

      // JSON'u temizle
      String cleanedJson = responseText;
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7);
      }
      if (cleanedJson.endsWith('```')) {
        cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
      }
      cleanedJson = cleanedJson.trim();

      final jsonData = json.decode(cleanedJson) as Map<String, dynamic>;

      // Boş JSON kontrolü
      if (jsonData.isEmpty || !jsonData.containsKey('name')) {
        throw Exception('Görüntüde yemek tespit edilemedi veya analiz edilemedi');
      }

      return FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: jsonData['name'] ?? 'Bilinmeyen Yemek',
        description: jsonData['description'] ?? '',
        imageUrl: imageFile.path,
        nutritionInfo: NutritionInfo.fromMap(jsonData['nutritionInfo'] ?? {}),
        ingredients: List<String>.from(jsonData['ingredients'] ?? []),
        allergens: List<String>.from(jsonData['allergens'] ?? []),
        consumedAt: DateTime.now(),
        portionSize: (jsonData['portionSize'] ?? 1.0).toDouble(),
        portionUnit: jsonData['portionUnit'] ?? 'porsiyon',
      );
    } catch (e) {
      // Fallback item döndürme, hata fırlat
      throw Exception('Yemek analiz edilemedi: $e');
    }
  }

  Future<List<String>> suggestSimilarFoods(String foodName) async {
    try {
      final prompt = '''
      "$foodName" yemeğine benzer 5 Türk yemeği öner.
      Sadece yemek isimlerini virgülle ayırarak listele, başka açıklama ekleme.
      Örnek: Pilav, Köfte, Dolma, Börek, Çorba
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      if (responseText.isEmpty) {
        return [];
      }

      return responseText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      print('Benzer yemek önerisi hatası: $e');
      return [];
    }
  }

  Future<String> generateMealRecommendation(
    double remainingCalories,
    List<String> allergies,
    List<String> dietaryRestrictions,
  ) async {
    try {
      final prompt = '''
      Kalan kalori: $remainingCalories
      Alerjiler: ${allergies.join(', ')}
      Diyet kısıtlamaları: ${dietaryRestrictions.join(', ')}
      
      Bu bilgilere göre sağlıklı bir öğün önerisi yap. Türkçe olarak kısa ve net bir öneri ver.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text?.trim() ?? 'Öğün önerisi oluşturulamadı.';
    } catch (e) {
      print('Öğün önerisi hatası: $e');
      return 'Öğün önerisi oluşturulamadı.';
    }
  }
} 