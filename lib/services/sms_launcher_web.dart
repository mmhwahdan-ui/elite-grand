import 'package:web/web.dart' as web;

void launchSmsUri(String phone, String message) {
  try {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final encoded = Uri.encodeComponent(message);
    final uri = 'sms:$cleanPhone?body=$encoded';
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = uri;
    anchor.target = '_blank';
    anchor.click();
  } catch (_) {}
}

void launchWhatsAppUri(String phone, String message) {
  try {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '20${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('20') && cleanPhone.length == 10) {
      cleanPhone = '20$cleanPhone';
    }
    final encoded = Uri.encodeComponent(message);
    final uri = 'https://wa.me/$cleanPhone?text=$encoded';
    web.window.open(uri, '_blank');
  } catch (_) {}
}
