import 'package:flutter/material.dart';

import '../../core/app_snackbar.dart';
import '../../core/main_navigation_shell.dart';
import '../../data/services/auth_service.dart';
import '../company_panel/company_panel_shell.dart';
import '../admin_panel/admin_panel.dart';
import '../page2_3_4_sign_up/page3_signup_user_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continueToApp() async {
    final user = await _authService.getCurrentUser();
    if (!mounted) return;

    final Widget destination = switch (user.effectiveRole) {
      'ADMIN' => const AdminPanelScreen(),
      'COMPANY_MANAGER' ||
      'COMPANY_OPERATOR' ||
      'STATION_MANAGER' ||
      'STATION_OPERATOR' when user.companyId != null => CompanyPanelShell(
        currentUser: user,
      ),
      'COMPANY_MANAGER' ||
      'COMPANY_OPERATOR' ||
      'STATION_MANAGER' ||
      'STATION_OPERATOR' => const _UnauthorizedCompanyPanel(),
      _ => const MainNavigationShell(),
    };

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  void _openSignupFlow() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SignupUserPage()));
  }

  Future<void> _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      _showError('Phone/email and password are required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.login(
        identifier: identifier,
        password: password,
        rememberMe: _rememberMe,
      );
      if (!mounted) return;
      await _continueToApp();
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    AppSnackBar.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset('assets/images/logo.png', width: 150),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Charge the Future',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _identifierController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'E-mail',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text('Remember me', style: textTheme.bodyMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : _openSignupFlow,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            54,
                            177,
                            202,
                          ),
                          foregroundColor: const Color.fromARGB(255, 35, 8, 93),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            54,
                            177,
                            202,
                          ),
                          foregroundColor: const Color.fromARGB(255, 35, 8, 93),
                        ),
                        child: _isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Login'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => const MainNavigationShell(),
                            ),
                          );
                        },
                  child: const Text('Continue as Guest \u2192'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnauthorizedCompanyPanel extends StatelessWidget {
  const _UnauthorizedCompanyPanel();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      body: SafeArea(
        child: Center(
          child: Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Company access unavailable'),
              subtitle: Text('This account has no active company membership.'),
            ),
          ),
        ),
      ),
    );
  }
}
