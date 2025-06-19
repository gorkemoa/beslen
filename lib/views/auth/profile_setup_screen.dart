import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../service/firebase_service.dart';
import '../home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isAnonymous;
  
  const ProfileSetupScreen({
    super.key,
    this.isAnonymous = false,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _firebaseService = FirebaseService();
  
  Gender _selectedGender = Gender.other;
  ActivityLevel _selectedActivity = ActivityLevel.moderate;
  List<String> _allergies = [];
  bool _isLoading = false;

  final List<String> _commonAllergies = [
    'Gluten', 'Süt', 'Yumurta', 'Fındık', 'Soya', 'Balık', 'Kabuklu Deniz Ürünleri', 'Susam'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Kurulumu'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Kişisel Bilgileriniz',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Size özel beslenme planı oluşturmak için bilgilerinize ihtiyacımız var',
                style: TextStyle(color: Colors.grey),
              ),
              
              const SizedBox(height: 32),
              
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Ad gerekli' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Age & Gender Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Yaş',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final age = int.tryParse(value ?? '');
                        return age == null || age < 1 ? 'Geçerli yaş girin' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<Gender>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Cinsiyet',
                        border: OutlineInputBorder(),
                      ),
                      items: Gender.values.map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender.name),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedGender = value!),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Weight & Height Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Kilo (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final weight = double.tryParse(value ?? '');
                        return weight == null || weight < 1 ? 'Geçerli kilo girin' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Boy (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final height = double.tryParse(value ?? '');
                        return height == null || height < 1 ? 'Geçerli boy girin' : null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Activity Level
              DropdownButtonFormField<ActivityLevel>(
                value: _selectedActivity,
                decoration: const InputDecoration(
                  labelText: 'Aktivite Seviyesi',
                  border: OutlineInputBorder(),
                ),
                items: ActivityLevel.values.map((level) => DropdownMenuItem(
                  value: level,
                  child: Text(level.description),
                )).toList(),
                onChanged: (value) => setState(() => _selectedActivity = value!),
              ),
              
              const SizedBox(height: 24),
              
              // Allergies Section
              const Text(
                'Alerjileriniz',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Alerjik olduğunuz besinleri seçin',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                children: _commonAllergies.map((allergy) => FilterChip(
                  label: Text(allergy),
                  selected: _allergies.contains(allergy),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _allergies.add(allergy);
                      } else {
                        _allergies.remove(allergy);
                      }
                    });
                  },
                )).toList(),
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Profili Kaydet', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final age = int.parse(_ageController.text);
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);

      final profile = UserProfile(
        id: _firebaseService.userId,
        email: widget.isAnonymous ? null : _firebaseService.currentUser?.email,
        name: _nameController.text,
        age: age,
        weight: weight,
        height: height,
        gender: _selectedGender,
        activityLevel: _selectedActivity,
        allergies: _allergies,
        dailyCalorieGoal: _calculateCalorieGoal(weight, height, age),
        isAnonymous: widget.isAnonymous,
        createdAt: DateTime.now(),
      );

      await _firebaseService.saveUserProfile(profile);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil kaydedilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateCalorieGoal(double weight, double height, int age) {
    // Basic calorie calculation based on activity level
    final bmr = _selectedGender == Gender.male
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;
    return bmr * _selectedActivity.multiplier;
  }
} 