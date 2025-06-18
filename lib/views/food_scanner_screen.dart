import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../viewmodel/app_viewmodel.dart';
import '../service/ai_service.dart';
import '../service/firebase_service.dart';
import '../models/food_item.dart';

class FoodScannerScreen extends StatefulWidget {
  final String? mealType;
  
  const FoodScannerScreen({super.key, this.mealType});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final AIService _aiService = AIService();
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
        });
        await _analyzeImage();
      }
    } catch (e) {
      _showErrorSnackBar('Kamera erişimi başarısız: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
        });
        await _analyzeImage();
      }
    } catch (e) {
      _showErrorSnackBar('Galeri erişimi başarısız: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _aiService.analyzeFoodImage(_selectedImage!);
      setState(() {
        _analysisResult = result;
      });
    } catch (e) {
      _showErrorSnackBar('Analiz başarısız: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _saveFoodItem() async {
    if (_analysisResult == null || _selectedImage == null) return;

    final appViewModel = Provider.of<AppViewModel>(context, listen: false);
    final firebaseService = FirebaseService();
    final user = firebaseService.currentUser;

    if (user == null) {
      _showErrorSnackBar('Kullanıcı bulunamadı');
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // FoodItem ID'sini önce oluştur
      final foodItemId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Resmi base64 olarak Firestore'da sakla
      final imageUrl = await firebaseService.saveImageAsBase64(_selectedImage!, foodItemId);

      if (imageUrl != null) {
        final foodItem = FoodItem(
          id: foodItemId,
          name: _analysisResult!['name'],
          imageUrl: imageUrl, // Base64 data URL
          calories: _analysisResult!['calories'],
          protein: _analysisResult!['protein'],
          carbs: _analysisResult!['carbs'],
          fat: _analysisResult!['fat'],
          scannedAt: DateTime.now(),
          userId: user.uid,
        );

        final success = await appViewModel.saveFoodItem(foodItem);
        if (success && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yemek başarıyla kaydedildi!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorSnackBar('Yemek kaydedilemedi. Lütfen tekrar deneyin.');
        }
      } else {
        _showErrorSnackBar('Resim kaydedilemedi. Resim çok büyük olabilir, lütfen daha küçük bir resim seçin.');
      }
    } catch (e) {
      _showErrorSnackBar('Kaydetme hatası: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.mealType != null ? '${widget.mealType} - Yemek Tara' : 'Yemek Tara'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_selectedImage == null) ...[
              _buildImageSelectionCard(context),
            ] else ...[
              _buildImagePreviewCard(context),
              const SizedBox(height: 16),
              if (_isAnalyzing) ...[
                _buildAnalyzingCard(context),
              ] else if (_analysisResult != null) ...[
                _buildResultCard(context),
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelectionCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Yemek Fotoğrafı Çekin',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI ile yemeğinizin besin değerlerini analiz edin',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Kamera butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Galeri butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeri'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _analysisResult = null;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeni Fotoğraf'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Fotoğraf Analiz Ediliyor...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI yemeğinizin besin değerlerini hesaplıyor',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    final name = _analysisResult!['name'] ?? 'Bilinmeyen Yemek';
    final calories = _analysisResult!['calories'] ?? 0;
    final protein = _analysisResult!['protein'] ?? 0.0;
    final carbs = _analysisResult!['carbs'] ?? 0.0;
    final fat = _analysisResult!['fat'] ?? 0.0;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Besin değerleri
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildNutritionRow('Kalori', '$calories kcal', Icons.local_fire_department),
                  const SizedBox(height: 12),
                  _buildNutritionRow('Protein', '${protein.toStringAsFixed(1)}g', Icons.fitness_center),
                  const SizedBox(height: 12),
                  _buildNutritionRow('Karbonhidrat', '${carbs.toStringAsFixed(1)}g', Icons.grass),
                  const SizedBox(height: 12),
                  _buildNutritionRow('Yağ', '${fat.toStringAsFixed(1)}g', Icons.opacity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _analysisResult = null;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isAnalyzing ? null : _saveFoodItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isAnalyzing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Kaydet'),
          ),
        ),
      ],
    );
  }
} 