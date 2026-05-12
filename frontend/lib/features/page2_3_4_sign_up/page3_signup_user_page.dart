import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'page4_vehicle_info_page.dart';

class SignupUserPage extends StatefulWidget {
  const SignupUserPage({super.key, String phoneNumber = ''})
    : initialPhoneNumber = phoneNumber;

  final String initialPhoneNumber;

  @override
  State<SignupUserPage> createState() => _SignupUserPageState();
}

class _SignupUserPageState extends State<SignupUserPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.initialPhoneNumber.replaceFirst(RegExp(r'^\+90'), ''),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehicleInfoPage(
          phoneNumber: '+90${_phoneController.text.trim()}',
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FFFB), Color(0xFFEFF8F8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical -
                    36,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Log out'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const _SignupLogo(size: 108),
                    const SizedBox(height: 18),
                    Text(
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step into the future and charge with ease.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        final phone = value?.trim() ?? '';
                        if (phone.isEmpty) {
                          return 'Phone number is required';
                        }
                        if (phone.length != 10) {
                          return 'Phone number must be 10 digits';
                        }
                        if (!phone.startsWith('5')) {
                          return 'Phone number must start with 5';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if ((value?.trim() ?? '').length < 3) {
                          return 'Full name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Email',
                        prefixIcon: const Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Email is required';
                        }
                        if (!email.contains('@') || !email.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Show' : 'Hide',
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
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirmPassword ? 'Show' : 'Hide',
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords must match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 26),
                    _GradientButton(label: 'Continue', onPressed: _continue),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.78),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: colorScheme.outline.withValues(alpha: 0.55),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF25B7D3), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.error, width: 1.5),
    ),
  );
}

class _SignupLogo extends StatelessWidget {
  const _SignupLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF39C1D6), Color(0xFF1E9FBC)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E9FBC).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF18305F),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}
