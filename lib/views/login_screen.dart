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
      backgroundColor: Colors.white,
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
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.restaurant_menu,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        
        // Başlık
        Text(
          'beslen',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E7D32),
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 8),
        
        // Alt başlık
        Text(
          'Sağlıklı beslenmenin akıllı yolu',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        Text(
          'Giriş yapın ve beslenme yolculuğunuza başlayın',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginButtons() {
    return Column(
      children: [
        // Google ile giriş
        _buildSocialLoginButton(
          icon: Icons.g_mobiledata,
          text: 'Google ile Giriş Yap',
          color: Colors.red,
          onPressed: _isLoading ? null : _handleGoogleSignIn,
        ),
        const SizedBox(height: 16),
        
        // Apple ile giriş (iOS için)
        if (Theme.of(context).platform == TargetPlatform.iOS)
          Column(
            children: [
              _buildSocialLoginButton(
                icon: Icons.apple,
                text: 'Apple ile Giriş Yap',
                color: Colors.black,
                onPressed: _isLoading ? null : _handleAppleSignIn,
              ),
              const SizedBox(height: 16),
            ],
          ),
        
        // E-posta ile giriş
        _buildSocialLoginButton(
          icon: Icons.email_outlined,
          text: 'E-posta ile Giriş Yap',
          color: const Color(0xFF4CAF50),
          onPressed: _isLoading ? null : _navigateToEmailLogin,
        ),
      ],
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: color.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildGuestLogin() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleAnonymousSignIn,
        icon: const Icon(Icons.person_outline, size: 24),
        label: Text(
          _isLoading ? 'Giriş yapılıyor...' : 'Misafir Olarak Devam Et',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4CAF50),
          side: BorderSide(color: const Color(0xFF4CAF50).withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyInfo() {
    return Column(
      children: [
        Text(
          'Giriş yaparak Kullanım Koşulları ve Gizlilik Politikamızı kabul etmiş olursunuz.',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        // Loading indicator
        if (_isLoading)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
      ],
    );
  }
} 