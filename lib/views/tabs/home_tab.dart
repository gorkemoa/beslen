import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';
import '../../viewmodel/app_viewmodel.dart';
import '../../models/food_item.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize localization for date formatting
    Intl.defaultLocale = 'tr_TR';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Beslen',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AppViewModel>(
        builder: (context, appViewModel, child) {
          if (appViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => appViewModel.loadTodaysFoods(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, appViewModel),
                  const SizedBox(height: 24),
                  Text('Günlük Özet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDailySummary(context, appViewModel),
                  const SizedBox(height: 16),
                  _buildWaterIntakeCard(context),
                  const SizedBox(height: 16),
                  _buildMealsCard(context),
                  const SizedBox(height: 16),
                  _buildRecentScansCard(context, appViewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppViewModel appViewModel) {
    final profile = appViewModel.userProfile;
    final targetCalories = profile?.dailyCalorieNeeds ?? 2000;
    final percentage = appViewModel.caloriePercentage;

    final now = DateTime.now();
    final dayFormat = DateFormat('d MMMM yyyy, EEEE');
    final formattedDate = dayFormat.format(now);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba, ${profile?.name ?? 'Misafir'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Günlük hedef: ${targetCalories.round()} kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 9,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Center(
                  child: Text(
                    '${(percentage * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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

  Widget _buildDailySummary(BuildContext context, AppViewModel appViewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildNutrientInfo(
          context,
          'Kalori',
          '${appViewModel.todaysCalories.round()}',
          'kcal',
          const Color(0xFFE3F2FD),
          const Color(0xFF2196F3),
        ),
        _buildNutrientInfo(
          context,
          'Protein',
          '${appViewModel.todaysProtein.round()}',
          'g',
          const Color(0xFFFCE4EC),
          const Color(0xFFE91E63),
        ),
        _buildNutrientInfo(
          context,
          'Karb',
          '${appViewModel.todaysCarbs.round()}',
          'g',
          const Color(0xFFFFF8E1),
          const Color(0xFFFFA000),
        ),
        _buildNutrientInfo(
          context,
          'Yağ',
          '${appViewModel.todaysFat.round()}',
          'g',
          const Color(0xFFE8F5E9),
          const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildNutrientInfo(BuildContext context, String name, String value, String unit, Color bgColor, Color textColor) {
    final itemWidth = (MediaQuery.of(context).size.width - 32 - 3 * 8) / 4;
    return Container(
      width: itemWidth,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              color: textColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntakeCard(BuildContext context) {
    const double currentWater = 1.2;
    const double targetWater = 2.5;
    const double progress = currentWater / targetWater;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Su Tüketimi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('$currentWater / $targetWater L', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Icon(Icons.remove),
                  style: OutlinedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(width: 24),
                const Icon(Icons.local_drink_outlined, color: Color(0xFF4A90E2), size: 28),
                const SizedBox(width: 8),
                const Text('200 ml', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                OutlinedButton(
                  onPressed: () {},
                  child: const Icon(Icons.add),
                  style: OutlinedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMealsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Öğünler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMealItem(context, Icons.local_cafe_outlined, 'Kahvaltı', const Color(0xFFFFF8E1), Colors.orange),
                _buildMealItem(context, Icons.restaurant_outlined, 'Öğle', const Color(0xFFE8F5E9), Colors.green),
                _buildMealItem(context, Icons.nightlight_outlined, 'Akşam', const Color(0xFFE3F2FD), Colors.blue),
                _buildMealItem(context, Icons.apple_outlined, 'Atıştırma', const Color(0xFFFCE4EC), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(BuildContext context, IconData icon, String name, Color bgColor, Color iconColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: bgColor,
          child: Icon(icon, size: 30, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRecentScansCard(BuildContext context, AppViewModel appViewModel) {
    final recentFoods = appViewModel.todaysFoods.take(5).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Son Taramalar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (recentFoods.isNotEmpty)
                  TextButton(
                    onPressed: () {},
                    child: const Text('Tümünü Gör'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentFoods.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Henüz yemek taramadınız', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentFoods.length,
                  itemBuilder: (context, index) {
                    return _buildFoodItem(context, recentFoods[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFoodItem(BuildContext context, FoodItem food) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            width: double.infinity,
            child: _buildFoodImage(food.imageUrl),
          ),
          const SizedBox(height: 8),
          Text(
            food.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFoodImage(String imageUrl) {
    Widget imageWidget;
    if (imageUrl.isEmpty) {
      imageWidget = _buildFallbackIcon();
    } else if (imageUrl.startsWith('data:image')) {
      try {
        final parts = imageUrl.split(',');
        if (parts.length == 2) {
          final bytes = base64Decode(parts[1]);
          imageWidget = Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildFallbackIcon());
        } else {
          imageWidget = _buildFallbackIcon();
        }
      } catch (e) {
        imageWidget = _buildFallbackIcon();
      }
    } else {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildFallbackIcon(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        height: 80,
        width: double.infinity,
        child: imageWidget,
        color: Colors.grey.shade200,
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.restaurant,
        color: Colors.grey.shade400,
        size: 40,
      ),
    );
  }
} 