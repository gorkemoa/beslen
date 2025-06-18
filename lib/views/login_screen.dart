import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../viewmodel/app_viewmodel.dart';
import 'email_login_screen.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  Future<void> _handleGoogleSignIn() async {
    _setLoading(true);
    final appViewModel = Provider.of<AppViewModel>(context, listen: false);
    
    try {
      final success = await appViewModel.signInWithGoogle();
      if (success && mounted) {
        _navigateAfterLogin(appViewModel);
      } else if (mounted) {
        _showError('Google ile giriş yapılamadı. Lütfen tekrar deneyin.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Google giriş hatası: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    _setLoading(true);
    final appViewModel = Provider.of<AppViewModel>(context, listen: false);
    
    try {
      final success = await appViewModel.signInWithApple();
      if (success && mounted) {
        _navigateAfterLogin(appViewModel);
      } else if (mounted) {
        _showError('Apple ile giriş yapılamadı. Lütfen tekrar deneyin.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Apple giriş hatası: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    _setLoading(true);
    final appViewModel = Provider.of<AppViewModel>(context, listen: false);
    
    try {
      final success = await appViewModel.signInAnonymously();
      if (success && mounted) {
        _navigateAfterLogin(appViewModel);
      } else if (mounted) {
        _showError('Misafir girişi yapılamadı. Lütfen tekrar deneyin.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Misafir giriş hatası: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  void _navigateToEmailLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EmailLoginScreen()),
    );
  }

  void _navigateAfterLogin(AppViewModel appViewModel) {
    if (appViewModel.hasProfile) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 600),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: [
                  const SizedBox(height: 60),
                  
                  // Logo ve başlık
                  _buildHeader(),
                  
                  const SizedBox(height: 60),
                  
                  // Giriş butonları
                  _buildLoginButtons(),
                  
                  const SizedBox(height: 40),
                  
                  // Ayırıcı
                  _buildDivider(),
                  
                  const SizedBox(height: 40),
                  
                  // Misafir girişi
                  _buildGuestLogin(),
                  
                  const SizedBox(height: 40),
                  
                  // Gizlilik bilgisi
                  _buildPrivacyInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.restaurant_menu,
            size: 50,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 24),
        
        // Başlık
        Text(
          'beslen',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sağlıklı beslenmenin akıllı yolu',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginButtons() {
    return Column(
      children: [
        // Google Giriş
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: Icon(Icons.g_mobiledata, color: Theme.of(context).colorScheme.onPrimary),
            label: Text(
              'Google ile Giriş Yap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Apple Giriş
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleAppleSignIn,
            icon: Icon(Icons.apple, color: Theme.of(context).colorScheme.onSurface),
            label: Text(
              'Apple ile Giriş Yap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // E-posta Giriş
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _navigateToEmailLogin,
            icon: Icon(
              Icons.email_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              'E-posta ile Giriş Yap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ya da',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }

  Widget _buildGuestLogin() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton.icon(
        onPressed: _isLoading ? null : _handleAnonymousSignIn,
        icon: Icon(
          Icons.person_outline,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        label: Text(
          'Misafir Olarak Devam Et',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyInfo() {
    return Text(
      'Giriş yaparak Kullanım Koşulları ve Gizlilik Politikasını kabul etmiş olursunuz.',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingOverlay() {
    if (!_isLoading) return const SizedBox.shrink();
    
    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
} 