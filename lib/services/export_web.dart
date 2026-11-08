import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

void saveAndDownloadFile(String content, String fileName, String mimeType) {
  // UTF-8 BOM for Microsoft Excel Arabic support
  final bom = '\uFEFF';
  final fullContent = bom + content;
  final bytes = utf8.encode(fullContent);
  
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
