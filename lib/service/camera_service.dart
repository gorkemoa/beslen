import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<File?> takeFoodPhoto() async {
    try {
      // Kamera iznini kontrol et
      final cameraPermission = await Permission.camera.status;
      if (cameraPermission.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          throw 'Kamera izni gerekli';
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw 'Fotoğraf çekilemedi: $e';
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      // Galeri iznini kontrol et
      final storagePermission = await Permission.photos.status;
      if (storagePermission.isDenied) {
        final result = await Permission.photos.request();
        if (result.isDenied) {
          throw 'Galeri izni gerekli';
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw 'Resim seçilemedi: $e';
    }
  }

  Future<List<File>> pickMultipleImages() async {
    try {
      final storagePermission = await Permission.photos.status;
      if (storagePermission.isDenied) {
        final result = await Permission.photos.request();
        if (result.isDenied) {
          throw 'Galeri izni gerekli';
        }
      }

      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      throw 'Resimler seçilemedi: $e';
    }
  }

  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  Future<bool> checkGalleryPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  Future<bool> requestGalleryPermission() async {
    final result = await Permission.photos.request();
    return result.isGranted;
  }
} 