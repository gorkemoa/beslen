import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/app_viewmodel.dart';
import '../login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Consumer<AppViewModel>(
        builder: (context, appViewModel, child) {
          final profile = appViewModel.userProfile;
          
          if (profile == null) {
            return _buildNoProfileState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(context, profile),
                const SizedBox(height: 20),
                _buildStatsCard(context, profile),
                const SizedBox(height: 16),
                _buildInfoCard(context, profile),
                const SizedBox(height: 16),
                _buildSignOutCard(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoProfileState(BuildContext context) {
    return const Center(
      child: Text('Profil bilgisi bulunamadı'),
    );
  }

  Widget _buildProfileHeader(BuildContext context, profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${profile.age} yaş',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vücut Bilgileri',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Kilo',
                    '${profile.weight.round()} kg',
                    Icons.monitor_weight,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Boy',
                    '${profile.height.round()} cm',
                    Icons.height,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Günlük Kalori',
                    '${profile.dailyCalorieNeeds.round()}',
                    Icons.local_fire_department,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
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

  Widget _buildInfoCard(BuildContext context, profile) {
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hedef ve Aktivite',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'Hedef', goalText, Icons.shutter_speed),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Aktivite Seviyesi', activityText, Icons.fitness_center),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
} 