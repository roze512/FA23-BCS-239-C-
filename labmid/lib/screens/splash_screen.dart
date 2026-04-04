import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../services/firestore_sync_service.dart';
import '../services/settings_service.dart';
import '../services/backup_service.dart';
import '../utils/constants.dart';

/// Splash screen with Velocity POS branding
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _animationController.forward();
    
    // Animate progress bar
    _animateProgress();
    
    // Check user and navigate
    _checkUserAndNavigate();
  }

  void _animateProgress() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _progress = 1.0;
        });
      }
    });
  }

  Future<void> _checkUserAndNavigate() async {
    // Show splash for 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check if user is remembered
    final prefs = await SharedPreferences.getInstance();
    final isRemembered = prefs.getBool('remember_me') ?? false;
    final userId = prefs.getString('user_id');
    
    // Check Firebase auth state
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (isRemembered && userId != null && currentUser != null) {
      // User is logged in and remembered
      try {
        // Download latest data from Firestore
        await FirestoreSyncService().downloadAllFromCloud();
        
        // Start auto-sync
        FirestoreSyncService().startAutoSync();
        
        // Auto-Backup Check (Every 24 Hours)
        final settingsService = SettingsService();
        final autoBackup = await settingsService.getAutoBackupEnabled();
        if (autoBackup) {
          final lastBackup = await settingsService.getLastBackupTime();
          final driveEmail = await settingsService.getGoogleDriveEmail();
          
          // If Drive is connected and 24 hours have passed
          if (driveEmail != null && 
              (lastBackup == null || DateTime.now().difference(lastBackup).inHours >= 24)) {
            final backupService = BackupService();
            // Verify silent sign-in succeeds before attempting backup
            final signedInEmail = await backupService.getSignedInEmail();
            if (signedInEmail != null) {
              // Fire and forget - don't block app launch
              backupService.backupDatabase().then((success) {
                if (success) debugPrint('Auto-backup completed successfully in background.');
              }).catchError((e) {
                debugPrint('Auto-backup failed: $e');
              });
            } else {
              debugPrint('Auto-backup skipped: Google account not signed in.');
              // Clear stale email so Settings shows correct state
              await settingsService.clearGoogleDriveEmail();
            }
          }
        }
      } catch (e) {
        debugPrint('Error syncing data: $e');
      }
      
      // Navigate to Home (and NEVER come back to splash)
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      // New user or not remembered - go to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Ambient glow effects
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with neon glow
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceDark,
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.2),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt,
                        size: 60,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // App name with styled POS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Velocity ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'POS',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: AppTheme.primaryGreen.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Tagline
                    Text(
                      'Manage. Sell. Grow.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // Loading progress with percentage
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 2500),
                            curve: Curves.easeOut,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: AppTheme.surfaceDark,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryGreen,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Version text at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'v1.0.2',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
