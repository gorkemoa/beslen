import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodel/dashboard_viewmodel.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/progress_card.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/recent_foods_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beslen'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardViewModel>().refreshData();
            },
          ),
        ],
      ),
      body: Consumer<DashboardViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.refreshData(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.refreshData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Karşılama
                  _buildGreeting(context, viewModel),
                  const SizedBox(height: 24),
                  
                  // Kalori Progress Kartı
                  ProgressCard(
                    title: 'Günlük Kalori',
                    value: viewModel.todayCalories,
                    target: viewModel.userProfile?.dailyCalorieNeeds ?? 2000,
                    unit: 'kcal',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  
                  // Besin Değerleri Kartları
                  Row(
                    children: [
                      Expanded(
                        child: NutritionCard(
                          title: 'Protein',
                          value: viewModel.todayProtein,
                          unit: 'g',
                          color: Colors.blue,
                          icon: Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NutritionCard(
                          title: 'Karbonhidrat',
                          value: viewModel.todayCarbs,
                          unit: 'g',
                          color: Colors.orange,
                          icon: Icons.grain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: NutritionCard(
                          title: 'Yağ',
                          value: viewModel.todayFat,
                          unit: 'g',
                          color: Colors.red,
                          icon: Icons.opacity,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NutritionCard(
                          title: 'Öğün',
                          value: viewModel.todaysFoods.length.toDouble(),
                          unit: 'adet',
                          color: Colors.green,
                          icon: Icons.restaurant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Son Yemekler
                  RecentFoodsCard(
                    foods: viewModel.todaysFoods.take(3).toList(),
                    onDeleteFood: (foodId) => viewModel.deleteFoodItem(foodId),
                  ),
                  const SizedBox(height: 16),
                  
                  // Günlük Öneriler
                  RecommendationCard(
                    recommendations: viewModel.dailyRecommendations,
                  ),
                  const SizedBox(height: 100), // Bottom navigation için boşluk
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, DashboardViewModel viewModel) {
    final now = DateTime.now();
    final timeOfDay = now.hour < 12 
        ? 'Günaydın' 
        : now.hour < 18 
            ? 'İyi günler' 
            : 'İyi akşamlar';
    
    final userName = viewModel.userProfile?.name ?? 'Kullanıcı';
    final todayText = DateFormat('d MMMM yyyy', 'tr_TR').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$timeOfDay, $userName!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          todayText,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
} 