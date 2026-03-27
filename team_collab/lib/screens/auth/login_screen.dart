import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailController.text.trim(), _passwordController.text);
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), 
                  blurRadius: 32, 
                  offset: const Offset(0, 16)
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'images/logo.png',
                          height: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 48, height: 48, 
                            decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(12)), 
                            child: const Icon(Icons.group, color: Colors.white, size: 28)
                          ),
                        ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 24),
                        const Text('TeamCollab', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 40),
                        const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                          .animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: 6),
                        const Text('Sign in to your workspace', style: TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center)
                          .animate().fadeIn(delay: 400.ms),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration('admin@admin.com', context),
                    validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration('••••••••', context).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(auth.error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor, 
                        foregroundColor: theme.colorScheme.onPrimary, 
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: auth.isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.05),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, BuildContext context) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
    filled: true,
    fillColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
