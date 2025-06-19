import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();
  List<CameraDescription>? _cameras;
  CameraController? _controller;

  Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      throw Exception('Kameralar başlatılamadı: $e');
    }
  }

  Future<CameraController?> initializeCamera() async {
    if (_cameras == null || _cameras!.isEmpty) {
      await initializeCameras();
    }

    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('Kullanılabilir kamera bulunamadı');
    }

    try {
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      return _controller;
    } catch (e) {
      throw Exception('Kamera başlatılamadı: $e');
    }
  }

  Future<File?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Kamera başlatılmamış');
    }

    try {
      final image = await _controller!.takePicture();
      return File(image.path);
    } catch (e) {
      throw Exception('Fotoğraf çekilemedi: $e');
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Galeri fotoğrafı seçilemedi: $e');
    }
  }

  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Kamera fotoğrafı çekilemedi: $e');
    }
  }

  void dispose() {
    _controller?.dispose();
  }

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  CameraController? get controller => _controller;
} 