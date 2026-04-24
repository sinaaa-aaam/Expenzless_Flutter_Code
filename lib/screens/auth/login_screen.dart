// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_button.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.signIn(_emailCtrl.text, _passCtrl.text);
    if (!mounted) return;
    if (auth.status == AuthStatus.authenticated) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Login failed'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.tealBg,
                    borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.wallet, color: AppColors.teal, size: 30),
                ),
                const SizedBox(height: 24),
                const Text('Welcome back',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                    color: AppColors.slate800)),
                const SizedBox(height: 8),
                const Text('Log in to track your expenses',
                  style: TextStyle(fontSize: 15, color: AppColors.slate600)),
                const SizedBox(height: 40),

                AppTextField(
                  controller: _emailCtrl, label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) => (v == null || !v.contains('@'))
                    ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passCtrl, label: 'Password',
                  hint: '••••••••', obscure: _obscure,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.slate400),
                    onPressed: () => setState(() => _obscure = !_obscure)),
                  validator: (v) => (v == null || v.length < 6)
                    ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPassword(context),
                    child: const Text('Forgot password?',
                      style: TextStyle(color: AppColors.teal)),
                  ),
                ),
                const SizedBox(height: 24),
                LoadingButton(
                  label: 'Log In',
                  loading: auth.status == AuthStatus.loading,
                  onPressed: _login,
                ),
                const SizedBox(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account? ",
                    style: TextStyle(color: AppColors.slate600)),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text('Sign up',
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

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: AppTextField(controller: ctrl, label: 'Email',
          hint: 'you@example.com', keyboardType: TextInputType.emailAddress),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<AuthProvider>().resetPassword(ctrl.text);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset email sent!')));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
