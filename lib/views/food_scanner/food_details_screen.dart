import 'package:flutter/material.dart';
import '../../models/food_item.dart';

class FoodDetailsScreen extends StatefulWidget {
  final FoodItem food;
  final Function(FoodItem) onSave;

  const FoodDetailsScreen({
    super.key,
    required this.food,
    required this.onSave,
  });

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _portionController;
  late FoodItem _currentFood;

  @override
  void initState() {
    super.initState();
    _currentFood = widget.food;
    _nameController = TextEditingController(text: widget.food.name);
    _portionController = TextEditingController(text: widget.food.portionSize.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _portionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemek Detayları'),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Kaydet', style: TextStyle(color: Color(0xFF4CAF50))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Food Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Yemek Adı',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _currentFood = _currentFood.copyWith(name: value);
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Portion Size
            TextFormField(
              controller: _portionController,
              decoration: const InputDecoration(
                labelText: 'Porsiyon Boyutu',
                border: OutlineInputBorder(),
                suffixText: 'porsiyon',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final portion = double.tryParse(value) ?? 1.0;
                setState(() {
                  final multiplier = portion / _currentFood.portionSize;
                  _currentFood = _currentFood.copyWith(
                    portionSize: portion,
                    nutritionInfo: widget.food.nutritionInfo * multiplier,
                  );
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Nutrition Info Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Besin Değerleri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildNutritionRow('Kalori', '${_currentFood.nutritionInfo.calories.toInt()} kcal'),
                    _buildNutritionRow('Protein', '${_currentFood.nutritionInfo.protein.toStringAsFixed(1)}g'),
                    _buildNutritionRow('Karbonhidrat', '${_currentFood.nutritionInfo.carbohydrates.toStringAsFixed(1)}g'),
                    _buildNutritionRow('Yağ', '${_currentFood.nutritionInfo.fat.toStringAsFixed(1)}g'),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _saveChanges() {
    widget.onSave(_currentFood);
    Navigator.of(context).pop();
  }
} 