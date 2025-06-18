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
  late AnimationController _rippleController;
  late AnimationController _particleController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  
  late Animation<double> _waveAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _dropAnimation;
  // ignore: unused_field
  late Animation<double> _waterAmountAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  
  // Local state for smooth animations
  double _localWaterAmount = 0.0;
  double _localWaterTarget = 2.5;
  bool _isInitialized = false;
  
  // Particle system
  List<Map<String, dynamic>> _particles = [];

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

    // Ripple animasyonu
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rippleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    // Particle animasyonu
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _particleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));

    // Bounce animasyonu
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Pulse animasyonu (sürekli)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _buttonController.dispose();
    _dropController.dispose();
    _waterAmountController.dispose();
    _rippleController.dispose();
    _particleController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
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
          if (appViewModel.isLoading && !_isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await appViewModel.loadTodaysFoods();
              // Refresh sonrası local state'i güncelle
              setState(() {
                _localWaterAmount = appViewModel.todaysWaterAmount;
                _localWaterTarget = appViewModel.waterTarget;
              });
            },
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
                Row(
                  children: [
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
                    const SizedBox(width: 8),
                    _buildSleepWakeButton(context, appViewModel),
                  ],
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
    // İlk yüklemede local state'i güncelle (sadece bir kez)
    if (!_isInitialized) {
      _localWaterAmount = appViewModel.todaysWaterAmount;
      _localWaterTarget = appViewModel.waterTarget;
      _isInitialized = true;
    }
    
    final currentWater = _localWaterAmount;
    final targetWater = _localWaterTarget;
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
            
                        // Süper animasyonlu progress bar
                Container(
              height: 24,
                  decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade300,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Arka plan gradient
                Container(
                      height: 24,
                  decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade200,
                            Colors.grey.shade300,
                          ],
                        ),
                      ),
                    ),
                    // Su seviyesi - Gelişmiş animasyon
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      tween: Tween<double>(begin: 0, end: progress),
                      builder: (context, animatedProgress, child) {
                        return AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 24,
                              width: ((MediaQuery.of(context).size.width - 64) * animatedProgress * (1.0 + _bounceAnimation.value * 0.05)).clamp(0.0, MediaQuery.of(context).size.width - 64),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    const Color(0xFF4A90E2).withOpacity(0.7),
                                    const Color(0xFF4A90E2),
                                    const Color(0xFF6BB6FF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4A90E2).withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                    ),
                  ],
                ),
                            );
                          },
                        );
                      },
                    ),
                    // Dalga efekti - Gelişmiş
                    if (progress > 0)
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        tween: Tween<double>(begin: 0, end: progress),
                        builder: (context, animatedProgress, child) {
                          return AnimatedBuilder(
                            animation: _waveAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                size: Size(((MediaQuery.of(context).size.width - 64) * animatedProgress).clamp(0.0, MediaQuery.of(context).size.width - 64), 24),
                                painter: WavePainter(
                                  waveValue: _waveAnimation.value,
                                  progress: animatedProgress,
                                ),
                              );
                            },
                          );
                        },
                      ),
                                         // Ripple efekti
                     AnimatedBuilder(
                       animation: _rippleAnimation,
                       builder: (context, child) {
                         if (_rippleAnimation.value == 0) return const SizedBox.shrink();
                         return Positioned.fill(
                           child: Container(
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(
                                 color: const Color(0xFF4A90E2).withOpacity(0.3 * (1 - _rippleAnimation.value)),
                                 width: 2 * _rippleAnimation.value,
                               ),
                             ),
                           ),
                         );
                       },
                     ),
                    // Shimmer efekti
                    if (progress > 0)
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            height: 24,
                            width: ((MediaQuery.of(context).size.width - 64) * progress).clamp(0.0, MediaQuery.of(context).size.width - 64),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-1.0 + _pulseAnimation.value * 2, 0),
                                end: Alignment(1.0 + _pulseAnimation.value * 2, 0),
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
          ],
        ),
      ),
    );
                        },
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
                            // Süper animasyonlu butonlar
            Row(
                  mainAxisAlignment: MainAxisAlignment.center,
              children: [
                    // Remove button - Gelişmiş animasyon
                    AnimatedBuilder(
                      animation: Listenable.merge([_buttonScaleAnimation, _pulseAnimation]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonScaleAnimation.value * (0.95 + _pulseAnimation.value * 0.05),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 8 * _pulseAnimation.value,
                                  spreadRadius: 2 * _pulseAnimation.value,
                                ),
                              ],
                            ),
                            child: OutlinedButton(
                              onPressed: _localWaterAmount > 0 
                                ? () => _removeWaterAnimated(context, appViewModel)
                                : null,
                              child: Icon(
                                Icons.remove,
                                color: _localWaterAmount > 0 ? Colors.orange : Colors.grey,
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(12),
                                side: BorderSide(
                                  color: _localWaterAmount > 0 ? Colors.orange.shade300 : Colors.grey.shade300,
                                  width: 2,
                                ),
                                backgroundColor: _localWaterAmount > 0 
                                  ? Colors.orange.withOpacity(0.1) 
                                  : Colors.grey.withOpacity(0.05),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    
                    // Süper animasyonlu su damlası ikonu
                    AnimatedBuilder(
                      animation: Listenable.merge([_dropAnimation, _pulseAnimation, _bounceAnimation]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: (1.0 + (_dropAnimation.value * 0.3)) * (0.9 + _pulseAnimation.value * 0.1),
                          child: Transform.rotate(
                            angle: _dropAnimation.value * 0.2,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF4A90E2).withOpacity(0.2),
                                    const Color(0xFF4A90E2).withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4A90E2).withOpacity(0.3),
                                    blurRadius: 12 + _pulseAnimation.value * 8,
                                    spreadRadius: 2 + _pulseAnimation.value * 3,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.local_drink_outlined, 
                                color: Color.lerp(
                                  const Color(0xFF4A90E2), 
                                  const Color(0xFF6BB6FF), 
                                  _pulseAnimation.value
                                ), 
                                size: 32 + _bounceAnimation.value * 4,
                              ),
        ),
      ),
    );
                      },
                    ),
                    
                    const SizedBox(width: 12),
                    AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + _bounceAnimation.value * 0.1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF4A90E2).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '200 ml', 
              style: TextStyle(
                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A90E2),
              ),
            ),
          ),
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    
                    // Add button - Süper gelişmiş animasyon
                    AnimatedBuilder(
                      animation: Listenable.merge([_buttonScaleAnimation, _pulseAnimation]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonScaleAnimation.value * (0.95 + _pulseAnimation.value * 0.05),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A90E2).withOpacity(0.4),
                                  blurRadius: 12 * _pulseAnimation.value,
                                  spreadRadius: 3 * _pulseAnimation.value,
                                ),
                              ],
                            ),
                            child: OutlinedButton(
                              onPressed: () => _addWaterAnimated(context, appViewModel),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20 + _pulseAnimation.value * 2,
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(12),
                                side: const BorderSide(
                                  color: Color(0xFF4A90E2),
                                  width: 2,
                                ),
                                backgroundColor: const Color(0xFF4A90E2),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
            
            // Kompakt particle ve drop animasyon efekti
            SizedBox(
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Particle efekti
                  if (_particles.isNotEmpty)
                    AnimatedBuilder(
                      animation: _particleAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(double.infinity, 40),
                          painter: ParticleEffectPainter(
                            particles: _particles,
                            animationValue: _particleAnimation.value,
                          ),
                        );
                      },
                    ),
                  // Su damlası animasyon efekti
                  if (_dropAnimation.value > 0)
                    Center(
                      child: AnimatedBuilder(
                        animation: _dropAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -_dropAnimation.value * 35),
                            child: Opacity(
                              opacity: (1.0 - _dropAnimation.value).clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: _dropAnimation.value.clamp(0.1, 1.0),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A90E2),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4A90E2).withOpacity(0.5),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
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

  // Süper animasyonlu su ekleme fonksiyonu
  void _addWaterAnimated(BuildContext context, AppViewModel appViewModel) async {
    const double amount = 200; // 200ml varsayılan
    
    // Çoklu animasyon tetikleme
    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });
    
    _dropController.forward().then((_) {
      _dropController.reset();
    });
    
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
    
    // Kompakt particle efekti oluştur
    _particles.clear();
    for (int i = 0; i < 6; i++) {
      _particles.add({
        'x': 0.5 + (Random().nextDouble() - 0.5) * 0.25,
        'y': 0.7,
        'size': 3.0 + Random().nextDouble() * 4,
        'speed': 0.6 + Random().nextDouble() * 0.4,
      });
    }
    _particleController.forward().then((_) {
      _particleController.reset();
      _particles.clear();
    });
    
    // Optimistic update - UI'ı hemen güncelle
    setState(() {
      _localWaterAmount += amount / 1000; // ml'yi litreye çevir
    });
    
    // Gelişmiş SnackBar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
        children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
              ),
          const SizedBox(width: 12),
              Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    '${amount.toInt()}ml su eklendi!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                    'Toplam: ${(_localWaterAmount * 1000).toInt()}ml',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
                ),
              ],
            ),
          backgroundColor: const Color(0xFF4A90E2),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    
    // Arka planda Firebase'e kaydet (UI'ı etkilemeyecek şekilde)
    _saveWaterInBackground(appViewModel, amount, isAdd: true);
  }

  // Animasyonlu su çıkarma fonksiyonu
  void _removeWaterAnimated(BuildContext context, AppViewModel appViewModel) async {
    if (_localWaterAmount <= 0) return;
    
    const double amount = 200; // 200ml varsayılan
    
    // Buton animasyonu
    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });
    
    // Optimistic update - UI'ı hemen güncelle
    setState(() {
      _localWaterAmount = (_localWaterAmount - amount / 1000).clamp(0.0, double.infinity);
    });
    
    // SnackBar'ı hemen göster
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.remove_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('${amount.toInt()}ml su çıkarıldı'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

    // Arka planda Firebase'den sil (UI'ı etkilemeyecek şekilde)
    _saveWaterInBackground(appViewModel, amount, isAdd: false);
  }

  // Arka plan Firebase işlemleri
  void _saveWaterInBackground(AppViewModel appViewModel, double amount, {required bool isAdd}) async {
    try {
      bool success;
      if (isAdd) {
        success = await appViewModel.addWaterIntake(amount);
    } else {
        // Son su kaydını bul ve sil
        if (appViewModel.todaysWaterIntake.isNotEmpty) {
          final lastWaterIntake = appViewModel.todaysWaterIntake.first;
          success = await appViewModel.removeWaterIntake(lastWaterIntake.id);
        } else {
          success = false;
        }
      }
      
      if (!success) {
        // Başarısızsa geri al
        if (mounted) {
          setState(() {
            if (isAdd) {
              _localWaterAmount -= amount / 1000;
            } else {
              _localWaterAmount += amount / 1000;
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAdd 
                ? 'Su eklenirken hata oluştu, geri alındı' 
                : 'Su çıkarılırken hata oluştu, geri alındı'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Hata durumunda geri al
      if (mounted) {
        setState(() {
          if (isAdd) {
            _localWaterAmount -= amount / 1000;
          } else {
            _localWaterAmount += amount / 1000;
          }
        });
      }
    }
  }

  // Uyku/Uyanma butonu
  Widget _buildSleepWakeButton(BuildContext context, AppViewModel appViewModel) {
    final isSleeping = appViewModel.isSleeping;
    
    return GestureDetector(
      onTap: () => _handleSleepWakeAction(context, appViewModel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
          color: isSleeping 
              ? Colors.orange.withOpacity(0.9) 
              : Colors.purple.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSleeping ? Icons.wb_sunny : Icons.bedtime,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              isSleeping ? 'Uyandım' : 'Uyudum',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
            ),
          ),
        );
  }

  // Uyku/Uyanma işlemi
  void _handleSleepWakeAction(BuildContext context, AppViewModel appViewModel) async {
    final isSleeping = appViewModel.isSleeping;
    
    // Onay dialogu göster
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSleeping ? Icons.wb_sunny : Icons.bedtime,
              color: isSleeping ? Colors.orange : Colors.purple,
            ),
            const SizedBox(width: 8),
            Text(isSleeping ? 'Günaydın!' : 'İyi Geceler!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSleeping 
                  ? 'Yeni güne başlayalım mı? Dünkü veriler arşivde kalacak.' 
                  : 'Günlük verileriniz arşivlenecek ve yarın için sıfırlanacak. Emin misiniz?',
            ),
            if (isSleeping && appViewModel.userProfile?.lastSleepTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Uyku süreniz: ${_calculateSleepDuration(appViewModel.userProfile!.lastSleepTime!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSleeping ? Colors.orange : Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text(isSleeping ? 'Uyandım' : 'Uyudum'),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        bool success;
        if (isSleeping) {
          success = await appViewModel.wakeUp();
        } else {
          success = await appViewModel.goToSleep();
        }

        // Loading'i kapat
        if (context.mounted) Navigator.of(context).pop();

        if (success) {
          // Başarı mesajı
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      isSleeping ? Icons.wb_sunny : Icons.bedtime,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isSleeping 
                            ? 'Günaydın! Yeni güne başladınız.' + 
                              (appViewModel.userProfile?.lastSleepDuration != null 
                                  ? ' (${appViewModel.userProfile!.lastSleepDuration!.toStringAsFixed(1)}s uyudunuz)'
                                  : '')
                            : 'İyi geceler! Verileriniz arşivlendi.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: isSleeping ? Colors.orange : Colors.purple,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

          // Local state'i sıfırla
          setState(() {
            _localWaterAmount = 0.0;
            _isInitialized = false;
          });
        } else {
          // Hata mesajı
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('İşlem sırasında bir hata oluştu. Lütfen tekrar deneyin.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        // Loading'i kapat
        if (context.mounted) Navigator.of(context).pop();
        
        // Hata mesajı
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Uyku süresi hesaplama
  String _calculateSleepDuration(DateTime sleepTime) {
    final now = DateTime.now();
    final duration = now.difference(sleepTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    } else {
      return '${minutes}dk';
    }
  }
}

// Gelişmiş dalga animasyonu için custom painter
class WavePainter extends CustomPainter {
  final double waveValue;
  final double progress;

  WavePainter({required this.waveValue, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 3.0;
    final waveLength = size.width / 3;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 + 
          sin((x / waveLength * 2 * pi) + waveValue) * waveHeight +
          sin((x / waveLength * 4 * pi) + waveValue * 1.5) * (waveHeight * 0.5);
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

// Particle efekti için custom painter
class ParticleEffectPainter extends CustomPainter {
  final List<Map<String, dynamic>> particles;
  final double animationValue;

  ParticleEffectPainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = const Color(0xFF4A90E2).withOpacity(
          (1.0 - animationValue).clamp(0.0, 1.0),
        )
        ..style = PaintingStyle.fill;

      final x = size.width * particle['x'] + 
                (Random().nextDouble() - 0.5) * 15 * animationValue;
      final y = size.height * 0.8 - 
                size.height * animationValue * particle['speed'] * 1.2;
      final particleSize = (particle['size'] * 0.8) * (1.0 - animationValue * 0.3);

      // Ana particle
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );

      // Kompakt glow efekti
      final glowPaint = Paint()
        ..color = const Color(0xFF4A90E2).withOpacity(
          (1.0 - animationValue).clamp(0.0, 1.0) * 0.2,
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        particleSize * 1.5,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticleEffectPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
} 