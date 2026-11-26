import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'nurse_portal_screen.dart';
import '../services/pwa_install_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = context.read<AppProvider>();

    final success = await provider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        if (provider.isNurse) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NursePortalScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.loginError ?? 'خطأ في اسم المستخدم أو كلمة المرور',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppTheme.redDebt,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.primary,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hospital Logo & Name
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: AppTheme.accentBright,
                        size: 52,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'إيليت جراند',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'نظام إدارة ومتابعة وحسابات التمريض المنزلي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login Card
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'أدخل اسم المستخدم وكلمة المرور المسندة إليك:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Username Input
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'كود مقدم الخدمة أو اسم المستخدم (Code / Username)',
                                  hintText: 'لمقدمي الخدمة: الكود (مثال: CG-014) | للموظفين: اسم المستخدم',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                  helperText: 'تسجيل دخول التمريض يتم بكود مقدم الخدمة (وليس برقم الهاتف)',
                                  helperStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.accentBright),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال الكود أو اسم المستخدم' : null,
                              ),
                              const SizedBox(height: 16),

                              // Password Input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور (Password)',
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال كلمة المرور' : null,
                              ),
                              const SizedBox(height: 24),

                              // Submit Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text(
                                        'دخول إلى النظام',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PWA Install Button (For PC and Mobile devices without browser bar)
                    if (!PwaInstallService.isStandalone())
                      OutlinedButton.icon(
                        onPressed: () => PwaInstallService.handleInstallClick(context),
                        icon: const Icon(Icons.install_mobile_rounded, color: AppTheme.accentBright, size: 20),
                        label: const Text(
                          'تثبيت البرنامج على الجهاز (كمبيوتر / أندرويد)',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.accentBright, width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Cloud Sync indicator footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: provider.hasPendingOfflineSync
                                ? Colors.amber
                                : provider.isOnline
                                    ? AppTheme.accentBright
                                    : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            provider.hasPendingOfflineSync
                                ? 'وضع محلي (توجد بيانات محفوظة بانتظار الرفع السحابي)'
                                : provider.isOnline
                                    ? 'متصل بالسحابة 24/7 (يدعم العمل بدون إنترنت)'
                                    : 'الوضع المحلي (البيانات محفوظة على جهازك)',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontFamily: 'Cairo',
                            ),
                            textAlign: TextAlign.center,
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
    );
  }
}
