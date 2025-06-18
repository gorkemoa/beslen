import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../viewmodel/app_viewmodel.dart';
import '../../models/food_item.dart';
import '../../models/user_profile.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFoodHistoryTab(context),
                _buildSleepHistoryTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Icon(
              Icons.history,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geçmiş Arşivi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Yemek ve uyku verilerinizi inceleyin',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                DateFormat('d MMM', 'tr_TR').format(DateTime.now()),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.restaurant_menu),
            text: 'Yemek Geçmişi',
          ),
          Tab(
            icon: Icon(Icons.bedtime),
            text: 'Uyku Geçmişi',
          ),
        ],
      ),
    );
  }

  Widget _buildFoodHistoryTab(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, appViewModel, child) {
        if (appViewModel.isLoading) {
          return _buildLoadingState();
        }

        if (appViewModel.foodHistory.isEmpty) {
          return _buildEmptyFoodState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await appViewModel.loadFoodHistory();
          },
          child: _buildFoodList(context, appViewModel.foodHistory),
        );
      },
    );
  }

  Widget _buildSleepHistoryTab(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, appViewModel, child) {
        final profile = appViewModel.userProfile;
        if (profile == null) {
          return _buildEmptyProfileState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Uyku verilerini yenile
            await appViewModel.loadUserProfile();
          },
          child: _buildSleepHistoryList(context, appViewModel),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Veriler yükleniyor...'),
        ],
      ),
    );
  }

  Widget _buildEmptyFoodState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(80),
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz Yemek Geçmişi Yok',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'İlk yemeğinizi tarayarak beslenme geçmişinizi oluşturmaya başlayın',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Ana tab'a geç
                DefaultTabController.of(context)?.animateTo(0);
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('İlk Yemeği Tara'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProfileState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(80),
              ),
              child: const Icon(
                Icons.bedtime,
                size: 80,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Uyku Verisi Bulunamadı',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Uyku takibinizi başlatmak için profil ayarlarınızı tamamlayın',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodList(BuildContext context, List<FoodItem> foodHistory) {
    // Tarih bazlı gruplama
    final Map<String, List<FoodItem>> groupedByDate = {};
    
    for (final food in foodHistory) {
      final dateKey = DateFormat('yyyy-MM-dd').format(food.scannedAt);
      if (!groupedByDate.containsKey(dateKey)) {
        groupedByDate[dateKey] = [];
      }
      groupedByDate[dateKey]!.add(food);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

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
    final totalProtein = foods.fold(0.0, (sum, food) => sum + food.protein);
    final totalCarbs = foods.fold(0.0, (sum, food) => sum + food.carbs);
    final totalFat = foods.fold(0.0, (sum, food) => sum + food.fat);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarih başlığı ve özet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalCalories kcal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Besin değerleri özeti
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNutritionSummary('Protein', '${totalProtein.round()}g', Colors.red.shade400),
                    _buildNutritionSummary('Karbonhidrat', '${totalCarbs.round()}g', Colors.orange.shade400),
                    _buildNutritionSummary('Yağ', '${totalFat.round()}g', Colors.yellow.shade600),
                  ],
                ),
              ],
            ),
          ),
          
          // Yemek listesi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: foods.map((food) => _buildFoodCard(context, food)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodCard(BuildContext context, FoodItem food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
             padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildFoodImage(food.imageUrl),
          const SizedBox(width: 16),
          
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
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(food.scannedAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildNutritionChip('${food.calories} kcal', Colors.blue.shade400),
                    _buildNutritionChip('P: ${food.protein.round()}g', Colors.red.shade400),
                    _buildNutritionChip('K: ${food.carbs.round()}g', Colors.orange.shade400),
                    _buildNutritionChip('Y: ${food.fat.round()}g', Colors.yellow.shade600),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepHistoryList(BuildContext context, AppViewModel appViewModel) {
    final profile = appViewModel.userProfile!;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mevcut uyku durumu kartı
        _buildCurrentSleepStatus(context, appViewModel),
        const SizedBox(height: 16),
        
        // Uyku istatistikleri
        _buildSleepStats(context, profile),
        const SizedBox(height: 16),
        
        // Uyku geçmişi (simüle edilmiş - gerçek uygulamada veritabanından gelecek)
        _buildSleepHistoryCard(context),
      ],
    );
  }

  Widget _buildCurrentSleepStatus(BuildContext context, AppViewModel appViewModel) {
    final profile = appViewModel.userProfile!;
    
    return Container(
      padding: const EdgeInsets.all(20),
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
            blurRadius: 10,
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
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mevcut Uyku Durumu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appViewModel.isSleeping ? 'Uyuyor' : 'Uyanık',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (appViewModel.isSleeping) 
            _buildSleepingInfo(profile)
          else 
            _buildAwakeInfo(profile),
        ],
      ),
    );
  }

  Widget _buildSleepStats(BuildContext context, UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
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
                Icons.analytics,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Uyku İstatistikleri',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Son Uyku',
                  profile.lastSleepDuration != null 
                    ? '${profile.lastSleepDuration!.toStringAsFixed(1)}h'
                    : 'Bilinmiyor',
                  Colors.blue.shade400,
                  Icons.bedtime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Ortalama',
                  '7.5h', // Simüle edilmiş veri
                  Colors.green.shade400,
                  Icons.timeline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Bu Hafta',
                  '52.5h', // Simüle edilmiş veri
                  Colors.orange.shade400,
                  Icons.calendar_view_week,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Kalite',
                  _getSleepQuality(profile.lastSleepDuration ?? 7.5),
                  _getSleepQualityColor(profile.lastSleepDuration ?? 7.5),
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
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
      ),
    );
  }

  Widget _buildSleepHistoryCard(BuildContext context) {
    // Simüle edilmiş uyku geçmişi verisi
    final sleepHistory = _generateMockSleepHistory();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
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
                Icons.history,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Son 7 Gün',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...sleepHistory.map((sleep) => _buildSleepHistoryItem(sleep)).toList(),
        ],
      ),
    );
  }

  Widget _buildSleepHistoryItem(Map<String, dynamic> sleep) {
    final date = sleep['date'] as DateTime;
    final duration = sleep['duration'] as double;
    final bedTime = sleep['bedTime'] as String;
    final wakeTime = sleep['wakeTime'] as String;
    
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);
    
    String dateTitle;
    if (isToday) {
      dateTitle = 'Bugün';
    } else if (isYesterday) {
      dateTitle = 'Dün';
    } else {
      dateTitle = DateFormat('d MMM', 'tr_TR').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getSleepQualityColor(duration).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bedtime,
              color: _getSleepQualityColor(duration),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${duration.toStringAsFixed(1)}h',
                      style: TextStyle(
                        color: _getSleepQualityColor(duration),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$bedTime - $wakeTime',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getSleepQualityIcon(duration),
                      size: 14,
                      color: _getSleepQualityColor(duration),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getSleepQuality(duration),
                      style: TextStyle(
                        color: _getSleepQualityColor(duration),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateMockSleepHistory() {
    final history = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final duration = 6.5 + (i * 0.3) + (i.isEven ? 0.5 : -0.2);
      final bedHour = 23 + (i % 2);
      final wakeHour = bedHour + duration.round();
      
      history.add({
        'date': date,
        'duration': duration,
        'bedTime': '${bedHour}:${(i * 15) % 60}',
        'wakeTime': '${wakeHour}:${(i * 10) % 60}',
      });
    }
    
    return history;
  }

  String _getSleepQuality(double hours) {
    if (hours < 6) return 'Az';
    if (hours < 7) return 'Yetersiz';
    if (hours <= 9) return 'İdeal';
    return 'Fazla';
  }

  Color _getSleepQualityColor(double hours) {
    if (hours < 6) return Colors.red.shade400;
    if (hours < 7) return Colors.orange.shade400;
    if (hours <= 9) return Colors.green.shade400;
    return Colors.blue.shade400;
  }

  IconData _getSleepQualityIcon(double hours) {
    if (hours < 6) return Icons.sentiment_dissatisfied;
    if (hours < 7) return Icons.sentiment_neutral;
    if (hours <= 9) return Icons.sentiment_satisfied;
    return Icons.sentiment_very_satisfied;
  }

  Widget _buildFoodImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildFallbackIcon();
    }

    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
        return _buildFallbackIcon();
      }
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.schedule, color: Colors.white.withOpacity(0.9), size: 16),
            const SizedBox(width: 6),
            Text(
              'Uyku başlangıcı: ${DateFormat('HH:mm').format(sleepTime)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.timer, color: Colors.white.withOpacity(0.9), size: 16),
            const SizedBox(width: 6),
            Text(
              'Uyku süresi: ${hours}s ${minutes}dk',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        if (profile.lastWakeUpTime != null) ...[
          Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.white.withOpacity(0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                'Son uyanma: ${DateFormat('HH:mm').format(profile.lastWakeUpTime!)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        
        if (profile.lastSleepDuration != null) ...[
          Row(
            children: [
              Icon(Icons.bedtime, color: Colors.white.withOpacity(0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                'Son uyku süresi: ${profile.lastSleepDuration!.toStringAsFixed(1)} saat',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSleepQualityIndicator(profile.lastSleepDuration!),
        ],
      ],
    );
  }

  Widget _buildSleepQualityIndicator(double hours) {
    final quality = _getSleepQuality(hours);
    final color = _getSleepQualityColor(hours);
    final icon = _getSleepQualityIcon(hours);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            quality,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
} 