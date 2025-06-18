import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../viewmodel/app_viewmodel.dart';
import '../service/ai_service.dart';
import '../service/firebase_service.dart';
import '../models/food_item.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Yemek Tara'),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Yemek Fotoğrafı Çekin',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamerayı kullanarak yemeğinizin fotoğrafını çekin veya galeriden seçin',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Yeniden Çek'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Değiştir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Yemek Analiz Ediliyor...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lütfen bekleyin, yapay zeka yemeğinizi tanıyor',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analiz Tamamlandı!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              _analysisResult!['name'],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Güven: %${(_analysisResult!['confidence'] * 100).round()}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            
            // Nutrition info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kalori',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        '${_analysisResult!['calories']} kcal',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Protein',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        '${_analysisResult!['protein']}g',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Karbonhidrat',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        '${_analysisResult!['carbs']}g',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Yağ',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        '${_analysisResult!['fat']}g',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            child: const Text('Tekrar Dene'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isAnalyzing ? null : _saveFoodItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Kaydet'),
          ),
        ),
      ],
    );
  }
} 