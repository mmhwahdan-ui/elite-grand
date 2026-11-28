import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class EditCompanyDialog extends StatefulWidget {
  const EditCompanyDialog({super.key});

  @override
  State<EditCompanyDialog> createState() => _EditCompanyDialogState();
}

class _EditCompanyDialogState extends State<EditCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _subtitleController;
  late TextEditingController _logoUrlController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _nameController = TextEditingController(text: provider.companyName);
    _subtitleController = TextEditingController(text: provider.companySubtitle);
    _logoUrlController = TextEditingController(text: provider.companyLogoUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC59B6D).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.business_rounded, color: Color(0xFF9A7444), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تخصيص هوية واسم الشركة',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'تغيير اللوجو والاسم الظاهر في النظام والتقارير',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Preview Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1E36),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC59B6D).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFC59B6D)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _logoUrlController.text.trim().isNotEmpty
                              ? Image.network(
                                  _logoUrlController.text.trim(),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                                )
                              : Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.trim().isEmpty ? 'إيليت هوم كير' : _nameController.text.trim(),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _subtitleController.text.trim().isEmpty ? 'تمريض منزلي ورعاية صحية' : _subtitleController.text.trim(),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: Color(0xFFC59B6D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Company Name Input
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم الشركة / المؤسسة *',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      prefixIcon: const Icon(Icons.corporate_fare_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال اسم الشركة';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Company Subtitle Input
                  TextFormField(
                    controller: _subtitleController,
                    decoration: InputDecoration(
                      labelText: 'الوصف أو الشعار (مثال: تمريض منزلي ورعاية متكاملة)',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      prefixIcon: const Icon(Icons.subtitles_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Company Logo URL
                  TextFormField(
                    controller: _logoUrlController,
                    decoration: InputDecoration(
                      labelText: 'رابط اللوجو المخصص (URL) أو اتركه فارغاً للوجو الرسمي',
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      prefixIcon: const Icon(Icons.image_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      suffixIcon: _logoUrlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _logoUrlController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _nameController.text = 'إيليت هوم كير';
                          _subtitleController.text = 'تمريض منزلي ورعاية صحية متكاملة';
                          _logoUrlController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: const Text(
                          'استعادة الاسم واللوجو الرسمي',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final provider = context.read<AppProvider>();
                await provider.updateCompanyInfo(
                  name: _nameController.text,
                  subtitle: _subtitleController.text,
                  logoUrl: _logoUrlController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حفظ وتحديث هوية واسم الشركة بنجاح', style: TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: AppTheme.accent,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('حفظ التعديلات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
