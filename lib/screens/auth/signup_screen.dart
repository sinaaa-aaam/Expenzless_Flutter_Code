// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.signUp(_emailCtrl.text, _passCtrl.text, _nameCtrl.text.trim());
    if (!mounted) return;
    if (auth.isLoggedIn) {
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Sign up failed'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 6),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(backgroundColor: AppColors.white, elevation: 0,
        leading: BackButton(color: AppColors.slate800)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                    color: AppColors.slate800)),
                const SizedBox(height: 8),
                const Text('Start tracking your business expenses today',
                  style: TextStyle(fontSize: 15, color: AppColors.slate600)),
                const SizedBox(height: 32),

                AppTextField(controller: _nameCtrl, label: 'Full Name',
                  hint: 'Jane Doe', prefixIcon: Icons.person_outline,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                const SizedBox(height: 16),
                AppTextField(controller: _emailCtrl, label: 'Email',
                  hint: 'you@example.com', keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) => (v == null || !v.contains('@'))
                    ? 'Invalid email' : null),
                const SizedBox(height: 16),
                AppTextField(controller: _passCtrl, label: 'Password',
                  hint: '••••••••', obscure: _obscure,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.slate400),
                    onPressed: () => setState(() => _obscure = !_obscure)),
                  validator: (v) => (v == null || v.length < 6)
                    ? 'Min 6 characters' : null),
                const SizedBox(height: 16),
                AppTextField(controller: _confirmCtrl, label: 'Confirm Password',
                  hint: '••••••••', obscure: _obscure,
                  prefixIcon: Icons.lock_outlined,
                  validator: (v) => v != _passCtrl.text
                    ? 'Passwords do not match' : null),
                const SizedBox(height: 32),

                LoadingButton(
                  label: 'Create Account',
                  loading: auth.status == AuthStatus.loading,
                  onPressed: _signUp,
                ),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account? ',
                    style: TextStyle(color: AppColors.slate600)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Log in',
                      style: TextStyle(color: AppColors.teal,
                        fontWeight: FontWeight.w700)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
