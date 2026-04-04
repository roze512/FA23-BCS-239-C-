import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/settings_service.dart';
import '../../services/database_service.dart';
import '../../services/backup_service.dart';
import '../../providers/auth_provider.dart';

/// Settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final DatabaseService _databaseService = DatabaseService();
  final BackupService _backupService = BackupService();
  
  bool _autoBackupEnabled = false;
  bool _isBackingUp = false;
  DateTime? _lastBackupTime;
  String? _googleDriveEmail;
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkConnectivity();
  }

  Future<void> _loadSettings() async {
    try {
      final autoBackup = await _settingsService.getAutoBackupEnabled();
      final lastBackup = await _settingsService.getLastBackupTime();
      final storedEmail = await _settingsService.getGoogleDriveEmail();

      // Reconcile stored email with the actual Google sign-in state.
      // Silent sign-in confirms the session is still valid; if it fails,
      // clear the stale stored email so the UI shows "Not connected".
      final signedInEmail = await _backupService.getSignedInEmail();
      if (signedInEmail != null && signedInEmail != storedEmail) {
        await _settingsService.setGoogleDriveEmail(signedInEmail);
      } else if (signedInEmail == null && storedEmail != null) {
        await _settingsService.clearGoogleDriveEmail();
      }
      
      setState(() {
        _autoBackupEnabled = autoBackup;
        _lastBackupTime = lastBackup;
        _googleDriveEmail = signedInEmail;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    setState(() {
      // result is now List<ConnectivityResult>, take the first one
      _connectivityStatus = result. isNotEmpty ? result.first : ConnectivityResult.none;
    });

    // Listen for connectivity changes
    connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      setState(() {
        _connectivityStatus = result. isNotEmpty ? result.first : ConnectivityResult.none;
      });
    });
  }

  Future<void> _backupData() async {
    if (_googleDriveEmail == null) {
      Fluttertoast.showToast(msg: 'Please connect to Google Drive first', backgroundColor: Colors.orange);
      return;
    }
    if (_connectivityStatus == ConnectivityResult.none) {
      Fluttertoast.showToast(msg: 'No internet connection', backgroundColor: Colors.orange);
      return;
    }

    setState(() => _isBackingUp = true);
    
    try {
      final success = await _backupService.backupDatabase();
      
      if (success) {
        final now = DateTime.now();
        setState(() {
          _lastBackupTime = now;
        });
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Data backed up successfully',
            backgroundColor: Colors.green,
          );
        }
      } else {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Backup failed',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Backup error: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _toggleAutoBackup(bool value) async {
    try {
      await _settingsService.setAutoBackupEnabled(value);
      setState(() {
        _autoBackupEnabled = value;
      });
      Fluttertoast.showToast(
        msg: value ? 'Auto backup enabled' : 'Auto backup disabled',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to update auto backup: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _connectGoogleDrive() async {
    try {
      final account = await _backupService.connectGoogleDrive();
      if (account != null) {
        await _settingsService.setGoogleDriveEmail(account.email);
        setState(() {
          _googleDriveEmail = account.email;
        });
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Google Drive connected',
            backgroundColor: Colors.green,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to connect Google Drive: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _disconnectGoogleDrive() async {
    try {
      await _backupService.disconnectGoogleDrive();
      await _settingsService.clearGoogleDriveEmail();
      setState(() {
        _googleDriveEmail = null;
      });
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Google Drive disconnected',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to disconnect: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _restoreData() async {
    if (_googleDriveEmail == null) {
      Fluttertoast.showToast(msg: 'Please connect to Google Drive first', backgroundColor: Colors.orange);
      return;
    }
    if (_connectivityStatus == ConnectivityResult.none) {
      Fluttertoast.showToast(msg: 'No internet connection', backgroundColor: Colors.orange);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.alertRed),
            SizedBox(width: 8),
            Text('Restore Data', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will replace all current data with backed up data. This action cannot be undone. Are you sure?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore', style: TextStyle(color: AppTheme.alertRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final success = await _backupService.restoreDatabase();
        
        // Hide loading
        if (mounted) Navigator.pop(context);
        
        if (success && mounted) {
          Fluttertoast.showToast(
            msg: 'Data restored successfully. Please restart app.',
            backgroundColor: Colors.green,
            toastLength: Toast.LENGTH_LONG,
          );
        } else if (mounted) {
          Fluttertoast.showToast(
            msg: 'Restore failed',
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        if (mounted) Navigator.pop(context); // hide loading
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Restore error: $e',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppTheme.alertRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Clear Remember Me preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('remember_me');
        await prefs.remove('user_id');
        await prefs.remove('login_method');
        
        // Sign out from Firebase and Google
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signOut();
        await _backupService.disconnectGoogleDrive();
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } catch (e) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Logout failed: $e',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Backup System Section
          _buildSectionTitle('Backup System'),
          const SizedBox(height: 12),
          
          // Backup Data Button
          _buildButton(
            label: 'Backup Data',
            icon: Icons.cloud_upload,
            color: AppTheme.primaryGreen,
            isLoading: _isBackingUp,
            onTap: _backupData,
          ),
          const SizedBox(height: 12),
          
          // Last Backup Info
          if (_lastBackupTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Last backup: ${_formatDateTime(_lastBackupTime!)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 12),
          
          // Auto Backup Toggle
          _buildSettingTile(
            title: 'Enable Auto Backup',
            subtitle: 'Automatically backup data every 24 hours',
            trailing: Switch(
              value: _autoBackupEnabled,
              onChanged: _toggleAutoBackup,
              activeColor: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          
          // Google Drive Connection
          _buildSettingTile(
            title: 'Google Drive',
            subtitle: _googleDriveEmail ?? 'Not connected',
            trailing: TextButton(
              onPressed: _googleDriveEmail == null
                  ? _connectGoogleDrive
                  : _disconnectGoogleDrive,
              child: Text(
                _googleDriveEmail == null ? 'Connect' : 'Disconnect',
                style: TextStyle(
                  color: _googleDriveEmail == null
                      ? AppTheme.primaryGreen
                      : AppTheme.alertRed,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Restore Data Button
          _buildButton(
            label: 'Restore Data',
            icon: Icons.cloud_download,
            color: AppTheme.alertRed,
            onTap: _restoreData,
          ),
          const SizedBox(height: 32),
          
          // General Settings Section
          _buildSectionTitle('General Settings'),
          const SizedBox(height: 12),
          
          // Connectivity Status
          _buildSettingTile(
            title: 'Connectivity Status',
            subtitle: _connectivityStatus == ConnectivityResult.none
                ? 'Offline'
                : 'Online',
            trailing: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _connectivityStatus == ConnectivityResult.none
                    ? AppTheme.alertRed
                    : AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Logout Button
          _buildButton(
            label: 'Logout',
            icon: Icons.logout,
            color: AppTheme.alertRed,
            onTap: _logout,
          ),
          const SizedBox(height: 32),
          
          // App Version Footer
          Center(
            child: Text(
              'App Version 1.0.0',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
