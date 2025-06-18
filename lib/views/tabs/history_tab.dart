import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../viewmodel/app_viewmodel.dart';
import '../../models/food_item.dart';
import '../../models/user_profile.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, appViewModel, child) {
        if (appViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (appViewModel.foodHistory.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await appViewModel.loadFoodHistory();
          },
          child: Column(
            children: [
              _buildSleepSummary(context, appViewModel),
              Expanded(child: _buildFoodList(context, appViewModel.foodHistory)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz Yemek Geçmişi Yok',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yemek taramaya başlayın',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to scanner - this would be handled by the parent widget
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('İlk Yemeği Tara'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(BuildContext context, List<FoodItem> foodHistory) {
    // Group by date
    final Map<String, List<FoodItem>> groupedByDate = {};
    
    for (final food in foodHistory) {
      final dateKey = DateFormat('yyyy-MM-dd').format(food.scannedAt);
      if (!groupedByDate.containsKey(dateKey)) {
        groupedByDate[dateKey] = [];
      }
      groupedByDate[dateKey]!.add(food);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final foodsForDate = groupedByDate[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        return _buildDateSection(context, date, foodsForDate);
      },
    );
  }

  Widget _buildDateSection(BuildContext context, DateTime date, List<FoodItem> foods) {
    final dateFormatter = DateFormat('d MMMM yyyy', 'tr_TR');
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);
    
    String dateTitle;
    if (isToday) {
      dateTitle = 'Bugün';
    } else if (isYesterday) {
      dateTitle = 'Dün';
    } else {
      dateTitle = dateFormatter.format(date);
    }
  

    final totalCalories = foods.fold(0, (sum, food) => sum + food.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalCalories kcal',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        ...foods.map((food) => _buildFoodCard(context, food)).toList(),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFoodCard(BuildContext context, FoodItem food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Food image
            _buildFoodImage(food.imageUrl),
            const SizedBox(width: 16),
            
            // Food details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(food.scannedAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Nutrition info
                  Wrap(
                    spacing: 16,
                    children: [
                      _buildNutritionChip(
                        '${food.calories} kcal',
                        Colors.blue.shade400,
                      ),
                      _buildNutritionChip(
                        'P: ${food.protein.round()}g',
                        Colors.red.shade400,
                      ),
                      _buildNutritionChip(
                        'K: ${food.carbs.round()}g',
                        Colors.orange.shade400,
                      ),
                      _buildNutritionChip(
                        'Y: ${food.fat.round()}g',
                        Colors.yellow.shade600,
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
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              width: 60,
              height: 60,
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 60,
              height: 60,
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.restaurant,
        color: Colors.grey.shade500,
        size: 30,
      ),
    );
  }

  Widget _buildNutritionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
           date.month == yesterday.month &&
           date.day == yesterday.day;
  }

  Widget _buildSleepSummary(BuildContext context, AppViewModel appViewModel) {
    final profile = appViewModel.userProfile;
    if (profile == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.purple.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                             Icon(
                 appViewModel.isSleeping ? Icons.bedtime : Icons.wb_sunny,
                 color: Colors.white,
                 size: 24,
               ),
              const SizedBox(width: 8),
              Text(
                'Uyku Durumu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
                     if (appViewModel.isSleeping) 
             _buildSleepingInfo(profile)
           else 
             _buildAwakeInfo(profile),
        ],
      ),
    );
  }

  Widget _buildSleepingInfo(UserProfile profile) {
    final sleepTime = profile.lastSleepTime!;
    final now = DateTime.now();
    final duration = now.difference(sleepTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Şu anda uyuyor 😴',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Uyku başlangıcı: ${DateFormat('HH:mm').format(sleepTime)}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        Text(
          'Uyku süresi: ${hours}s ${minutes}dk',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAwakeInfo(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uyanık 🌅',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        if (profile.lastWakeUpTime != null) ...[
          Text(
            'Son uyanma: ${DateFormat('HH:mm').format(profile.lastWakeUpTime!)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
        
        if (profile.lastSleepDuration != null) ...[
          Text(
            'Son uyku süresi: ${profile.lastSleepDuration!.toStringAsFixed(1)} saat',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          _buildSleepQualityIndicator(profile.lastSleepDuration!),
        ],
      ],
    );
  }

  Widget _buildSleepQualityIndicator(double hours) {
    String quality;
    Color color;
    IconData icon;

    if (hours < 6) {
      quality = 'Az uyku';
      color = Colors.red.shade300;
      icon = Icons.sentiment_dissatisfied;
    } else if (hours < 7) {
      quality = 'Yetersiz';
      color = Colors.orange.shade300;
      icon = Icons.sentiment_neutral;
    } else if (hours <= 9) {
      quality = 'İdeal uyku';
      color = Colors.green.shade300;
      icon = Icons.sentiment_satisfied;
    } else {
      quality = 'Fazla uyku';
      color = Colors.blue.shade300;
      icon = Icons.sentiment_very_satisfied;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          quality,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 