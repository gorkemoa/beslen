import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';
import '../../viewmodel/app_viewmodel.dart';
import '../../models/food_item.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _buttonController;
  late AnimationController _dropController;
  late AnimationController _waterAmountController;
  late Animation<double> _waveAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _dropAnimation;
  late Animation<double> _waterAmountAnimation;
  
  // Local state for smooth animations
  double _localWaterAmount = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Dalga animasyonu (sürekli)
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_waveController);

    // Buton animasyonu
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    // Su damlası animasyonu
    _dropController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _dropAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _dropController,
      curve: Curves.elasticOut,
    ));

    // Su miktarı animasyonu
    _waterAmountController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _waterAmountAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _waterAmountController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _buttonController.dispose();
    _dropController.dispose();
    _waterAmountController.dispose();
    super.dispose();
  }

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
                  _buildAnimatedWaterIntakeCard(context, appViewModel),
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

  Widget _buildAnimatedWaterIntakeCard(BuildContext context, AppViewModel appViewModel) {
    // İlk yüklemede local state'i güncelle
    if (_localWaterAmount == 0.0 && appViewModel.todaysWaterAmount > 0) {
      _localWaterAmount = appViewModel.todaysWaterAmount;
    }
    
    final currentWater = _localWaterAmount > 0 ? _localWaterAmount : appViewModel.todaysWaterAmount;
    final targetWater = appViewModel.waterTarget;
    final progress = targetWater > 0 ? (currentWater / targetWater).clamp(0.0, 1.0) : 0.0;

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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    '${currentWater.toStringAsFixed(1)} / ${targetWater.toStringAsFixed(1)} L',
                    key: ValueKey(currentWater),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Animasyonlu dalga progress bar
            Container(
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade300,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    // Arka plan
                    Container(
                      height: 20,
                      color: Colors.grey.shade300,
                    ),
                                         // Su seviyesi - Daha akıcı animasyon
                     TweenAnimationBuilder<double>(
                       duration: const Duration(milliseconds: 400),
                       curve: Curves.easeInOut,
                       tween: Tween<double>(begin: 0, end: progress),
                       builder: (context, animatedProgress, child) {
                         return Container(
                           height: 20,
                           width: (MediaQuery.of(context).size.width - 64) * animatedProgress,
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               colors: [
                                 const Color(0xFF4A90E2).withOpacity(0.8),
                                 const Color(0xFF4A90E2),
                               ],
                             ),
                           ),
                         );
                       },
                     ),
                                         // Dalga efekti
                     if (progress > 0)
                       TweenAnimationBuilder<double>(
                         duration: const Duration(milliseconds: 400),
                         curve: Curves.easeInOut,
                         tween: Tween<double>(begin: 0, end: progress),
                         builder: (context, animatedProgress, child) {
                           return AnimatedBuilder(
                             animation: _waveAnimation,
                             builder: (context, child) {
                               return CustomPaint(
                                 size: Size((MediaQuery.of(context).size.width - 64) * animatedProgress, 20),
                                 painter: WavePainter(
                                   waveValue: _waveAnimation.value,
                                   progress: animatedProgress,
                                 ),
                               );
                             },
                           );
                         },
                       ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Animasyonlu butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: OutlinedButton(
                    onPressed: appViewModel.todaysWaterIntake.isNotEmpty 
                      ? () => _removeWaterAnimated(context, appViewModel)
                      : null,
                    child: const Icon(Icons.remove),
                    style: OutlinedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                
                // Animasyonlu su damlası ikonu
                AnimatedBuilder(
                  animation: _dropAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_dropAnimation.value * 0.2),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.local_drink_outlined, 
                          color: Color(0xFF4A90E2), 
                          size: 28
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(width: 8),
                const Text('200 ml', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                
                ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: OutlinedButton(
                    onPressed: () => _addWaterAnimated(context, appViewModel),
                    child: const Icon(Icons.add),
                    style: OutlinedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      side: BorderSide(color: Colors.grey.shade300),
                      backgroundColor: const Color(0xFF4A90E2).withOpacity(0.1),
                    ),
                  ),
                ),
              ],
            ),
            
            // Su damlası animasyon efekti
            const SizedBox(height: 20),
            Center(
              child: AnimatedBuilder(
                animation: _dropAnimation,
                builder: (context, child) {
                  if (_dropAnimation.value == 0) return const SizedBox.shrink();
                  
                  return Transform.translate(
                    offset: Offset(0, -_dropAnimation.value * 30),
                    child: Opacity(
                      opacity: (1.0 - _dropAnimation.value).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _dropAnimation.value.clamp(0.1, 1.0),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4A90E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.water_drop,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
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

  // Animasyonlu su ekleme fonksiyonu
  void _addWaterAnimated(BuildContext context, AppViewModel appViewModel) async {
    // Buton animasyonu
    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });
    
    // Su damlası animasyonu
    _dropController.forward().then((_) {
      _dropController.reset();
    });
    
    const double amount = 200; // 200ml varsayılan
    
    final success = await appViewModel.addWaterIntake(amount);
    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.white),
                const SizedBox(width: 8),
                Text('${amount.toInt()}ml su eklendi'),
              ],
            ),
            backgroundColor: const Color(0xFF4A90E2),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Su eklenirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Animasyonlu su çıkarma fonksiyonu
  void _removeWaterAnimated(BuildContext context, AppViewModel appViewModel) async {
    // Buton animasyonu
    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });
    
    final lastWaterIntake = appViewModel.todaysWaterIntake.first;
    
    final success = await appViewModel.removeWaterIntake(lastWaterIntake.id);
    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.remove_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('${lastWaterIntake.amount.toInt()}ml su çıkarıldı'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Su çıkarılırken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Dalga animasyonu için custom painter
class WavePainter extends CustomPainter {
  final double waveValue;
  final double progress;

  WavePainter({required this.waveValue, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 4.0;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 + 
          sin((x / waveLength * 2 * pi) + waveValue) * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.waveValue != waveValue || oldDelegate.progress != progress;
  }
} 