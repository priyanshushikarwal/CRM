import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_mode.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const String _defaultEmail = 'admin@dooninfra.net';
  static const String _defaultPassword = '12345678';

  String _getLandingRouteForUser(UserModel? user) {
    return AppModeConfig.defaultRouteForUser(user);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials() {
    _emailController.text = _defaultEmail;
    _passwordController.text = _defaultPassword;
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final enteredEmail = _emailController.text.trim();
    final enteredPassword = _passwordController.text;
    if (!AppModeConfig.isInventoryOnly &&
        enteredEmail == _defaultEmail &&
        enteredPassword == _defaultPassword) {
      await Future.delayed(const Duration(milliseconds: 500)); // brief UX pause
      DemoSession.start(); // mark demo session so router allows navigation
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/dashboard');
      }
      return;
    }

    try {
      UserModel? loggedInUser;
      final response = await SupabaseService.signInWithEmail(
        email: enteredEmail,
        password: enteredPassword,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout:
            () =>
                throw Exception(
                  'Connection timed out. Please check your internet and try again.',
                ),
      );

      if (response.user != null) {
        try {
          final userResponse =
              await SupabaseService.from('users')
                  .select()
                  .eq('id', response.user!.id)
                  .maybeSingle();

          if (userResponse != null) {
            loggedInUser = UserModel.fromJson(userResponse);
            final isActive = loggedInUser!.isActive;

            if (!isActive) {
              await SupabaseService.signOut();
              setState(() {
                _errorMessage =
                    'Your account has been deactivated. Please contact the administrator.';
              });
              return;
            }

            if (AppModeConfig.isInventoryOnly &&
                !loggedInUser.canAccessInventory) {
              await SupabaseService.signOut();
              setState(() {
                _errorMessage =
                    'Inventory app access is not enabled for your account. Please ask admin to grant inventory access.';
              });
              return;
            }

            await SupabaseService.from('users')
                .update({'last_login_at': DateTime.now().toIso8601String()})
                .eq('id', response.user!.id);
          }
        } catch (dbError) {
          debugPrint('DEBUG: DB check error (non-fatal): $dbError');
        }

        ref.invalidate(currentUserProvider);
        if (mounted) {
          context.go(_getLandingRouteForUser(loggedInUser));
        }
        return;
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Login failed: No user returned. Please try again.';
          });
        }
        return;
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (mounted) {
        setState(() {
          if (msg.contains('Email not confirmed')) {
            _errorMessage =
                'Please confirm your email first. Check your inbox for a confirmation link.';
          } else if (msg.contains('Invalid login credentials') ||
              msg.contains('invalid_credentials')) {
            _errorMessage = 'Invalid email or password. Please try again.';
          } else if (msg.contains('User not found')) {
            _errorMessage = 'No account found with this email. Please sign up.';
          } else if (msg.contains('ERR_CONNECTION_TIMED_OUT') ||
              msg.contains('SocketException') ||
              msg.contains('Failed host lookup') ||
              msg.contains('XMLHttpRequest error')) {
            _errorMessage =
                'Cannot connect to server. Please check your internet connection or try again later.';
          } else {
            _errorMessage = 'Login error: $msg';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final isInventoryOnly = AppModeConfig.isInventoryOnly;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: GridPatternPainter()),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.solar_power_rounded,
                                size: 48,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              AppModeConfig.appHeadline,
                              style: AppTextStyles.heading1.copyWith(
                                color: Colors.white,
                                fontSize: 42,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppModeConfig.appSubtitle,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 48),
                            _buildFeatureItem(
                              isInventoryOnly
                                  ? Icons.inventory_2_rounded
                                  : Icons.dashboard_rounded,
                              isInventoryOnly
                                  ? 'Inventory Control'
                                  : 'Real-time Dashboard',
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                              isInventoryOnly
                                  ? Icons.qr_code_scanner_rounded
                                  : Icons.track_changes_rounded,
                              isInventoryOnly
                                  ? 'Barcode Scanning'
                                  : 'Application Tracking',
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                              Icons.cloud_sync_rounded,
                              'Cloud Sync',
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                              Icons.security_rounded,
                              isInventoryOnly
                                  ? 'Inventory Access Only'
                                  : 'Secure & Reliable',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 32,
                      left: 48,
                      child: Text(
                        AppConstants.companyName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            flex: isDesktop ? 4 : 1,
            child: Container(
              color: AppTheme.backgroundColor,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 64 : 24,
                    vertical: 48,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isDesktop) ...[
                            Center(
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.solar_power_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          Text(
                            'Welcome Back',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppModeConfig.loginSubtitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 40),
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.errorColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppTheme.errorColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppTheme.errorColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                              },
                              child: Text(
                                'Forgot Password?',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text('Sign In'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!isInventoryOnly) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/register'),
                                  child: Text(
                                    'Sign Up',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            GestureDetector(
                              onTap: _fillDemoCredentials,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.admin_panel_settings_rounded,
                                          size: 18,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Admin Login',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            'Tap to fill',
                                            style: AppTextStyles.caption.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildCredentialRow(
                                      Icons.email_outlined,
                                      'Email',
                                      _defaultEmail,
                                    ),
                                    const SizedBox(height: 6),
                                    _buildCredentialRow(
                                      Icons.lock_outlined,
                                      'Password',
                                      _defaultPassword,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..strokeWidth = 1;

    const spacing = 50.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
