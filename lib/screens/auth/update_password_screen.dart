import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/supabase_service.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      await SupabaseService.updateUserPassword(_passwordController.text);
      await SupabaseService.signOut(); // Clean up current auto-login session

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Please sign in with your new password.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      router.go('/login');
    } on Exception catch (e) {
      final msg = e.toString();
      setState(() {
        if (msg.contains('Password should be')) {
          _errorMessage = 'Password is too weak. Please use a stronger password.';
        } else {
          _errorMessage = 'Failed to update password: $msg';
        }
      });
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
                child: Center(
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
                          'Secure Your Account',
                          style: AppTextStyles.heading1.copyWith(
                            color: Colors.white,
                            fontSize: 42,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Update your password to ensure secure, ongoing access\nto your DoonInfra solar management panel.',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            'Update Password',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set a new secure password for your account.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
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
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'New Password',
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
                                return 'Please enter a new password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleUpdatePassword,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Update Password'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final router = GoRouter.of(context);
                                  await SupabaseService.signOut();
                                  router.go('/login');
                                },
                                child: Text(
                                  'Cancel & Go to Sign In',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}
