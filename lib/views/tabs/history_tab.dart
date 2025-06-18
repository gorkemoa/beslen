import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../viewmodel/app_viewmodel.dart';
import '../../models/food_item.dart';
import '../../models/user_profile.dart';
import '../../models/sleep_record.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey.shade50,
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
              color: Theme.of(context).colorScheme.onPrimary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geçmiş Arşivi',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Yemek ve uyku verilerinizi inceleyin',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                DateFormat('d MMM', 'tr_TR').format(DateTime.now()),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
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
        indicatorColor: Theme.of(context).colorScheme.onPrimary,
        indicatorWeight: 3,
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
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
             await appViewModel.loadSleepHistory();
             await appViewModel.loadSleepStatistics();
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'İlk yemeğinizi tarayarak beslenme geçmişinizi oluşturmaya başlayın',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.purple.withOpacity(0.2) : Colors.purple.withOpacity(0.1),
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Uyku takibinizi başlatmak için profil ayarlarınızı tamamlayın',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
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
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalCalories kcal',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodCard(BuildContext context, FoodItem food) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(food.scannedAt),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDarkMode ? Colors.black : Colors.grey.shade50,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mevcut uyku durumu kartı
          _buildCurrentSleepStatus(context, appViewModel),
          const SizedBox(height: 16),
          
                   // Uyku istatistikleri
           _buildSleepStats(context, appViewModel),
          const SizedBox(height: 16),
          
                   // Uyku geçmişi
           _buildSleepHistoryCard(context, appViewModel.sleepHistory),
        ],
      ),
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

  Widget _buildSleepStats(BuildContext context, AppViewModel appViewModel) {
    final stats = appViewModel.sleepStatistics;
    final profile = appViewModel.userProfile!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final averageDuration = stats['averageDuration'] ?? 0.0;
    final totalSleepTime = stats['totalSleepTime'] ?? 0.0;
    final recordCount = stats['recordCount'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                  averageDuration > 0 
                    ? '${averageDuration.toStringAsFixed(1)}h'
                    : 'Veri yok',
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
                  'Bu Ay',
                  totalSleepTime > 0 
                    ? '${totalSleepTime.toStringAsFixed(1)}h'
                    : 'Veri yok',
                  Colors.orange.shade400,
                  Icons.calendar_view_month,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Kayıt Sayısı',
                  recordCount > 0 ? '$recordCount gün' : 'Veri yok',
                  Colors.purple.shade400,
                  Icons.bar_chart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepHistoryCard(BuildContext context, List<SleepRecord> sleepHistory) {
    final displayHistory = sleepHistory.take(7).toList(); // Son 7 gün göster
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                'Son ${sleepHistory.length > 7 ? '7' : sleepHistory.length} Gün',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (displayHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.bedtime_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz uyku kaydı yok',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...displayHistory.map((sleep) => _buildSleepHistoryItemFromRecord(context, sleep)).toList(),
        ],
      ),
    );
  }

  Widget _buildSleepHistoryItemFromRecord(BuildContext context, SleepRecord sleep) {
    final date = sleep.sleepTime;
    final duration = sleep.duration ?? 0.0;
    final bedTime = DateFormat('HH:mm').format(sleep.sleepTime);
    final wakeTime = sleep.wakeUpTime != null 
        ? DateFormat('HH:mm').format(sleep.wakeUpTime!)
        : 'Devam ediyor';
    
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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade200),
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
                      duration > 0 ? '${duration.toStringAsFixed(1)}h' : 'Devam ediyor',
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
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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
                      sleep.qualityText,
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
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey.shade100,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
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