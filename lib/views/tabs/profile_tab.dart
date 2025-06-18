import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/app_viewmodel.dart';
import '../login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, appViewModel, child) {
        final isDarkMode = appViewModel.isDarkMode;
        final profile = appViewModel.userProfile;
        
        return Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.grey.shade50,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, isDarkMode),
              SliverToBoxAdapter(
                child: profile == null
                    ? _buildNoProfileState(context, isDarkMode)
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildProfileHeader(context, profile, isDarkMode),
                            const SizedBox(height: 20),
                            _buildStatsCard(context, profile, isDarkMode),
                            const SizedBox(height: 16),
                            _buildInfoCard(context, profile, isDarkMode),
                            const SizedBox(height: 16),
                            _buildDarkModeCard(context, isDarkMode, appViewModel),
                            const SizedBox(height: 16),
                            _buildSignOutCard(context, isDarkMode),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: isDarkMode 
          ? Colors.grey.shade900
          : Theme.of(context).colorScheme.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [Colors.grey.shade900, Colors.grey.shade800]
                  : [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDarkMode ? 'Karanlık' : 'Aydınlık',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoProfileState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(80),
              ),
              child: Icon(
                Icons.person_off,
                size: 64,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Profil bilgisi bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, profile, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isDarkMode 
            ? Border.all(color: Colors.grey.shade800, width: 1)
            : null,
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [Colors.blue.shade400, Colors.purple.shade400]
                    : [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.blue.shade400 : Theme.of(context).colorScheme.primary)
                      .withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            profile.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.grey.shade800
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${profile.age} yaş • ${profile.gender == 'male' ? 'Erkek' : 'Kadın'}',
              style: TextStyle(
                color: isDarkMode 
                    ? Colors.grey.shade300
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, profile, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isDarkMode 
            ? Border.all(color: Colors.grey.shade800, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: isDarkMode ? Colors.blue.shade400 : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Vücut Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Kilo',
                  '${profile.weight.round()} kg',
                  Icons.monitor_weight,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Boy',
                  '${profile.height.round()} cm',
                  Icons.height,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Günlük Kalori',
                  '${profile.dailyCalorieNeeds.round()}',
                  Icons.local_fire_department,
                  isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, IconData icon, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isDarkMode 
            ? Border.all(color: Colors.grey.shade700, width: 1)
            : null,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isDarkMode ? Colors.blue.shade400 : Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, profile, bool isDarkMode) {
    String goalText = switch (profile.goal) {
      'weight_loss' => 'Kilo Vermek',
      'weight_gain' => 'Kilo Almak',
      _ => 'Kilom Sabit Kalsın',
    };

    String activityText = switch (profile.activityLevel) {
      'light' => 'Az Aktif',
      'moderate' => 'Orta Aktif',
      'active' => 'Çok Aktif',
      _ => 'Hareketsiz',
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isDarkMode 
            ? Border.all(color: Colors.grey.shade800, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.track_changes,
                color: isDarkMode ? Colors.green.shade400 : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Hedef ve Aktivite',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(context, 'Hedef', goalText, Icons.shutter_speed, isDarkMode),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Aktivite Seviyesi', activityText, Icons.fitness_center, isDarkMode),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Su Hedefi', '${profile.dailyWaterTarget} L', Icons.water_drop, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isDarkMode 
            ? Border.all(color: Colors.grey.shade700, width: 1)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.blue.shade400.withOpacity(0.2)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.blue.shade400 : Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkModeCard(BuildContext context, bool isDarkMode, AppViewModel appViewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isDarkMode 
            ? Border.all(color: Colors.grey.shade800, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: isDarkMode ? Colors.purple.shade400 : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Görünüm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: isDarkMode 
                  ? Border.all(color: Colors.grey.shade700, width: 1)
                  : null,
            ),
                         child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: isDarkMode 
                             ? Colors.purple.shade400.withOpacity(0.2)
                             : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Icon(
                         isDarkMode ? Icons.dark_mode : Icons.light_mode,
                         color: isDarkMode ? Colors.purple.shade400 : Theme.of(context).colorScheme.primary,
                         size: 20,
                       ),
                     ),
                     const SizedBox(width: 16),
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'Tema Modu',
                           style: TextStyle(
                             color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                             fontSize: 12,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           isDarkMode ? 'Karanlık Mod' : 'Aydınlık Mod',
                           style: TextStyle(
                             fontWeight: FontWeight.w600,
                             fontSize: 16,
                             color: isDarkMode ? Colors.white : Colors.black87,
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
                 GestureDetector(
                   onTap: () => appViewModel.toggleTheme(),
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: isDarkMode 
                           ? Colors.purple.shade400
                           : Theme.of(context).colorScheme.primary,
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                         BoxShadow(
                           color: (isDarkMode ? Colors.purple.shade400 : Theme.of(context).colorScheme.primary)
                               .withOpacity(0.3),
                           blurRadius: 8,
                           offset: const Offset(0, 2),
                         ),
                       ],
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(
                           Icons.swap_horiz,
                           color: Colors.white,
                           size: 16,
                         ),
                         const SizedBox(width: 4),
                         Text(
                           'Değiştir',
                           style: const TextStyle(
                             color: Colors.white,
                             fontSize: 12,
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                       ],
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

  Widget _buildSignOutCard(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isDarkMode 
            ? Border.all(color: Colors.grey.shade800, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: isDarkMode ? Colors.red.shade400 : Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Hesap İşlemleri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showSignOutDialog(context, isDarkMode),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.red.shade400 : Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isDarkMode ? 0 : 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Çıkış Yap',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _signOut(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.red.shade400 : Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final appViewModel = Provider.of<AppViewModel>(context, listen: false);
      print('ProfileTab: Çıkış işlemi başlatılıyor...');
      
      await appViewModel.signOut();
      print('ProfileTab: AppViewModel signOut tamamlandı');

      if (context.mounted) {
        print('ProfileTab: Login sayfasına yönlendiriliyor...');
        // Loading indicator göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Çıkış yapılıyor...'),
            duration: const Duration(seconds: 1),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Kısa bir süre bekle ve login sayfasına yönlendir
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('ProfileTab: Çıkış yapma hatası: $e');
      
      if (context.mounted) {
        // Hata olsa bile login sayfasına yönlendir
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış tamamlandı (${e.toString().contains('channel-error') ? 'bağlantı hatası göz ardı edildi' : 'hata: $e'})'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Yine de login sayfasına yönlendir
        await Future.delayed(const Duration(milliseconds: 800));
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }
} 