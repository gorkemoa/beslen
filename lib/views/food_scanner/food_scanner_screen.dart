import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/food_scanner_viewmodel.dart';
import 'food_details_screen.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FoodScannerViewModel>(context, listen: false).loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemek Ekle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<FoodScannerViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading || viewModel.isAnalyzing) {
            return _buildLoadingState(viewModel);
          }

          if (viewModel.analyzedFood != null) {
            return _buildAnalyzedFoodState(viewModel);
          }

          return _buildInitialState(viewModel);
        },
      ),
    );
  }

  Widget _buildLoadingState(FoodScannerViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF4CAF50),
            strokeWidth: 3,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            viewModel.isAnalyzing 
              ? 'Yemek analiz ediliyor...' 
              : 'Yükleniyor...',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            viewModel.isAnalyzing
              ? 'AI yemeğinizin besin değerlerini hesaplıyor'
              : 'Lütfen bekleyin',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(FoodScannerViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            'Yemek Fotoğrafı Çekin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'AI teknolojisi yemeğinizi analiz ederek besin değerlerini otomatik olarak hesaplayacak',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Illustration
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Fotoğraf çekmek için\naşağıdaki butonları kullanın',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Camera Button
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _takePicture(viewModel),
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                'Kamera ile Çek',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Gallery Button
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _pickFromGallery(viewModel),
              icon: const Icon(Icons.photo_library),
              label: const Text(
                'Galeriden Seç',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
                side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          
          if (viewModel.error != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: viewModel.hasAllergenWarnings() 
                  ? Colors.orange[50] 
                  : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: viewModel.hasAllergenWarnings() 
                    ? Colors.orange 
                    : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    viewModel.hasAllergenWarnings() 
                      ? Icons.warning 
                      : Icons.error,
                    color: viewModel.hasAllergenWarnings() 
                      ? Colors.orange 
                      : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      viewModel.error!,
                      style: TextStyle(
                        color: viewModel.hasAllergenWarnings() 
                          ? Colors.orange[800] 
                          : Colors.red[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyzedFoodState(FoodScannerViewModel viewModel) {
    final food = viewModel.analyzedFood!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Food Image
          if (viewModel.capturedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                viewModel.capturedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Food Name
          Text(
            food.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          if (food.description.isNotEmpty)
            Text(
              food.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          
          const SizedBox(height: 20),
          
          // Nutrition Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Besin Değerleri (100g)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildNutritionRow('Kalori', '${food.nutritionInfo.calories.toInt()} kcal'),
                  _buildNutritionRow('Protein', '${food.nutritionInfo.protein.toStringAsFixed(1)}g'),
                  _buildNutritionRow('Karbonhidrat', '${food.nutritionInfo.carbohydrates.toStringAsFixed(1)}g'),
                  _buildNutritionRow('Yağ', '${food.nutritionInfo.fat.toStringAsFixed(1)}g'),
                  
                  if (food.nutritionInfo.fiber > 0)
                    _buildNutritionRow('Lif', '${food.nutritionInfo.fiber.toStringAsFixed(1)}g'),
                  
                  if (food.nutritionInfo.sugar > 0)
                    _buildNutritionRow('Şeker', '${food.nutritionInfo.sugar.toStringAsFixed(1)}g'),
                ],
              ),
            ),
          ),
          
          // Allergen Warning
          if (viewModel.hasAllergenWarnings()) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Alerji Uyarısı',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bu yemekte alerjiniz olan şu maddeler bulunabilir: ${viewModel.getAllergenWarnings().join(', ')}',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => viewModel.clearAll(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Yeniden Çek'),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _editAndSave(viewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Düzenle ve Kaydet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _takePicture(FoodScannerViewModel viewModel) async {
    try {
      await viewModel.takeFoodPhoto();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _pickFromGallery(FoodScannerViewModel viewModel) async {
    try {
      await viewModel.pickImageFromGallery();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editAndSave(FoodScannerViewModel viewModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FoodDetailsScreen(
          food: viewModel.analyzedFood!,
          onSave: (updatedFood) async {
            viewModel.updateFoodItem(updatedFood);
            await viewModel.saveFoodItem();
            
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Yemek başarıyla kaydedildi!'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            }
          },
        ),
      ),
    );
  }
} 