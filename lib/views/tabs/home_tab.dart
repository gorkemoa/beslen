import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../viewmodel/app_viewmodel.dart';
import '../../models/food_item.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'beslen',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<AppViewModel>(
        builder: (context, appViewModel, child) {
          if (appViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await appViewModel.loadTodaysFoods();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hoş geldin mesajı
                  _buildWelcomeCard(context, appViewModel),
                  const SizedBox(height: 16),
                  
                  // Günlük kalori kartı
                  _buildCalorieCard(context, appViewModel),
                  const SizedBox(height: 16),
                  
                  // Bugünün besin değerleri
                  _buildNutritionCard(context, appViewModel),
                  const SizedBox(height: 16),
                  
                  // Son taramalar
                  _buildRecentScansCard(context, appViewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, AppViewModel appViewModel) {
    final profile = appViewModel.userProfile;
    final timeOfDay = _getTimeOfDay();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$timeOfDay ${profile?.name ?? 'Misafir'}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bugün ne yiyorsunuz?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.waving_hand,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieCard(BuildContext context, AppViewModel appViewModel) {
    final profile = appViewModel.userProfile;
    final todaysCalories = appViewModel.todaysCalories;
    final targetCalories = profile?.dailyCalorieNeeds ?? 2000;
    final percentage = appViewModel.caloriePercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Günlük Kalori Hedefi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Kalori progress
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: MediaQuery.of(context).size.width * 0.8 * percentage,
                  decoration: BoxDecoration(
                    color: _getProgressColor(percentage),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tüketilen',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$todaysCalories kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Hedef',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${targetCalories.round()} kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(BuildContext context, AppViewModel appViewModel) {
    final protein = appViewModel.todaysProtein;
    final carbs = appViewModel.todaysCarbs;
    final fat = appViewModel.todaysFat;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bugünün Besin Değerleri',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildNutritionItem(
                    context,
                    'Protein',
                    '${protein.round()}g',
                    Colors.red.shade400,
                    'P',
                  ),
                ),
                Expanded(
                  child: _buildNutritionItem(
                    context,
                    'Karbonhidrat',
                    '${carbs.round()}g',
                    Colors.orange.shade400,
                    'K',
                  ),
                ),
                Expanded(
                  child: _buildNutritionItem(
                    context,
                    'Yağ',
                    '${fat.round()}g',
                    Colors.yellow.shade600,
                    'Y',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionItem(
    BuildContext context,
    String title,
    String value,
    Color color,
    String letter,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScansCard(BuildContext context, AppViewModel appViewModel) {
    final recentFoods = appViewModel.todaysFoods.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son Taramalar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                child: Column(
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Henüz yemek taramadınız',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recentFoods.map((food) => _buildFoodItem(context, food)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, FoodItem food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildFoodImage(food.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${food.calories} kcal • ${DateFormat('HH:mm').format(food.scannedAt)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Günaydın';
    } else if (hour < 17) {
      return 'İyi öğlen';
    } else {
      return 'İyi akşamlar';
    }
  }

  Widget _buildFoodImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildFallbackIcon();
    }

    // Base64 data URL kontrolü
    if (imageUrl.startsWith('data:image/')) {
      try {
        // Base64 kısmını ayır
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackIcon();
              },
            ),
          ),
        );
      } catch (e) {
        print('Base64 görsel decode hatası: $e');
        return _buildFallbackIcon();
      }
    }

    // Normal URL için (eski veriler)
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.restaurant,
        color: Colors.grey.shade500,
        size: 25,
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 0.5) {
      return Colors.green;
    } else if (percentage < 0.8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
} 