import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../viewmodel/app_viewmodel.dart';

class RecommendationsTab extends StatelessWidget {
  const RecommendationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, appViewModel, child) {
        if (!appViewModel.hasProfile) {
          return _buildNoProfileState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh logic can be added here if needed
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: AnimationLimiter(
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    _buildDailyAnalysisSection(context, appViewModel),
                    const SizedBox(height: 16),
                    _buildRecommendationsSection(context, appViewModel),
                    const SizedBox(height: 100), // Bottom padding for FAB
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoProfileState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Öneriler için Profil Gerekli',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Size özel öneriler için profil bilgilerinizi tamamlayın',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAnalysisSection(BuildContext context, AppViewModel appViewModel) {
    return FutureBuilder<Map<String, dynamic>>(
      future: appViewModel.getDailyNutritionAnalysis(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(context, 'Günlük analiz hazırlanıyor...');
        }
        
        if (snapshot.hasError) {
          return _buildErrorCard(context, 'Analiz hatası: ${snapshot.error}');
        }
        
        final analysis = snapshot.data ?? {};
        return _buildDailyAnalysisCard(context, analysis);
      },
    );
  }

  Widget _buildRecommendationsSection(BuildContext context, AppViewModel appViewModel) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: appViewModel.getFoodRecommendations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(context, 'Akıllı öneriler hazırlanıyor...');
        }
        
        if (snapshot.hasError) {
          return _buildErrorCard(context, 'Öneri hatası: ${snapshot.error}');
        }
        
        final recommendations = snapshot.data ?? [];
        return _buildRecommendationsCard(context, recommendations);
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAnalysisCard(BuildContext context, Map<String, dynamic> analysis) {
    final score = analysis['nutrition_score'] ?? 0;
    final analysisText = analysis['balance_analysis'] ?? '';
    final recommendations = List<String>.from(analysis['recommendations'] ?? []);
    final achievements = List<String>.from(analysis['achievements'] ?? []);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Günlük Beslenme Analizi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Score indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beslenme Skoru',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$score',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getScoreColor(score).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Icon(
                      _getScoreIcon(score),
                      color: _getScoreColor(score),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              analysisText,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Başarılarınız',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...achievements.map((achievement) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        achievement,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Öneriler',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context, List<Map<String, dynamic>> recommendations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Akıllı Yemek Önerileri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (recommendations.isEmpty)
              Text(
                'Şu anda öneri bulunmuyor.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              )
            else
              ...recommendations.map((rec) => _buildAdvancedRecommendationItem(
                context,
                rec,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedRecommendationItem(BuildContext context, Map<String, dynamic> recommendation) {
    final name = recommendation['name'] ?? '';
    final reason = recommendation['reason'] ?? '';
    final calories = recommendation['calories'] ?? 0;
    final protein = recommendation['protein'] ?? 0.0;
    final carbs = recommendation['carbs'] ?? 0.0;
    final fat = recommendation['fat'] ?? 0.0;
    final type = recommendation['type'] ?? 'food';
    final priority = recommendation['priority'] ?? 'medium';
    final preparationTime = recommendation['preparation_time'] ?? '';
    final healthBenefits = List<String>.from(recommendation['health_benefits'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPriorityColor(priority).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            priority == 'high' ? 'Öncelikli' : priority == 'medium' ? 'Orta' : 'Düşük',
                            style: TextStyle(
                              color: _getPriorityColor(priority),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (preparationTime.isNotEmpty)
                      Text(
                        '⏱️ $preparationTime',
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
          const SizedBox(height: 12),
          
          Text(
            reason,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Nutrition info
          Row(
            children: [
              _buildNutritionChip('🔥 $calories kcal', Colors.red),
              const SizedBox(width: 8),
              _buildNutritionChip('💪 ${protein.toStringAsFixed(1)}g', Colors.blue),
              const SizedBox(width: 8),
              _buildNutritionChip('🌾 ${carbs.toStringAsFixed(1)}g', Colors.orange),
              const SizedBox(width: 8),
              _buildNutritionChip('🥑 ${fat.toStringAsFixed(1)}g', Colors.green),
            ],
          ),
          
          if (healthBenefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Sağlık Faydaları:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            ...healthBenefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.fiber_manual_record, size: 4, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(int score) {
    if (score >= 80) return Icons.sentiment_very_satisfied;
    if (score >= 60) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'main':
        return Colors.blue;
      case 'snack':
        return Colors.orange;
      case 'drink':
        return Colors.cyan;
      case 'healthy':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'main':
        return Icons.restaurant;
      case 'snack':
        return Icons.cookie;
      case 'drink':
        return Icons.local_drink;
      case 'healthy':
        return Icons.eco;
      default:
        return Icons.fastfood;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 