import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/app_viewmodel.dart';
import '../models/user_profile.dart';
import '../service/firebase_service.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  String _selectedGoal = 'maintain';
  String _selectedActivity = 'sedentary';

  final List<Map<String, String>> _goals = [
    {'value': 'weight_loss', 'label': 'Kilo Vermek'},
    {'value': 'maintain', 'label': 'Kilom Sabit Kalsın'},
    {'value': 'weight_gain', 'label': 'Kilo Almak'},
  ];

  final List<Map<String, String>> _activities = [
    {'value': 'sedentary', 'label': 'Hareketsiz (Ofis işi)'},
    {'value': 'light', 'label': 'Az Aktif (Hafif egzersiz)'},
    {'value': 'moderate', 'label': 'Orta Aktif (Düzenli egzersiz)'},
    {'value': 'active', 'label': 'Çok Aktif (Yoğun egzersiz)'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final appViewModel = Provider.of<AppViewModel>(context, listen: false);
      final firebaseService = FirebaseService();
      final user = firebaseService.currentUser;
      
      if (user != null) {
        final profile = UserProfile(
          id: user.uid,
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text),
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          gender: 'other', // Varsayılan değer, daha sonra cinsiyet seçimi eklenebilir
          goal: _selectedGoal,
          activityLevel: _selectedActivity,
          dailyWaterTarget: (double.parse(_weightController.text) * 35 / 1000).clamp(1.5, 4.0),
        );

        final success = await appViewModel.saveUserProfile(profile);
        
        if (success && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil kaydedilirken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profil Kurulumu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Text(
                  'Hoş geldiniz!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Size özel öneriler sunabilmek için birkaç bilgiye ihtiyacımız var.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // İsim
                _buildInputCard(
                  title: 'İsminiz',
                  child: TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Adınızı girin',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'İsim giriniz';
                      }
                      return null;
                    },
                  ),
                ),

                // Yaş
                _buildInputCard(
                  title: 'Yaşınız',
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Yaşınızı girin',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      suffixText: 'yaş',
                      suffixStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Yaş giriniz';
                      }
                      final age = int.tryParse(value!);
                      if (age == null || age < 16 || age > 100) {
                        return 'Geçerli bir yaş giriniz (16-100)';
                      }
                      return null;
                    },
                  ),
                ),

                // Kilo
                _buildInputCard(
                  title: 'Kilonuz',
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Kilonuzu girin',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      suffixText: 'kg',
                      suffixStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Kilo giriniz';
                      }
                      final weight = double.tryParse(value!);
                      if (weight == null || weight < 30 || weight > 300) {
                        return 'Geçerli bir kilo giriniz (30-300 kg)';
                      }
                      return null;
                    },
                  ),
                ),

                // Boy
                _buildInputCard(
                  title: 'Boyunuz',
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Boyunuzu girin',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      suffixText: 'cm',
                      suffixStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Boy giriniz';
                      }
                      final height = double.tryParse(value!);
                      if (height == null || height < 100 || height > 250) {
                        return 'Geçerli bir boy giriniz (100-250 cm)';
                      }
                      return null;
                    },
                  ),
                ),

                // Hedef
                _buildSelectionCard(
                  title: 'Hedefiniz',
                  options: _goals,
                  selectedValue: _selectedGoal,
                  onChanged: (value) {
                    setState(() {
                      _selectedGoal = value!;
                    });
                  },
                ),

                // Aktivite seviyesi
                _buildSelectionCard(
                  title: 'Aktivite Seviyeniz',
                  options: _activities,
                  selectedValue: _selectedActivity,
                  onChanged: (value) {
                    setState(() {
                      _selectedActivity = value!;
                    });
                  },
                ),

                const SizedBox(height: 32),

                // Kaydet butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Profili Kaydet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required List<Map<String, String>> options,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: options.map((option) {
                  return RadioListTile<String>(
                    title: Text(
                      option['label']!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    value: option['value']!,
                    groupValue: selectedValue,
                    onChanged: onChanged,
                    activeColor: Theme.of(context).colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 