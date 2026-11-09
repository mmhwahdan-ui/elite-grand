import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void saveAndDownloadFile(String content, String fileName, String mimeType) {
  final bom = '\uFEFF';
  final fullContent = bom + content;
  final bytes = utf8.encode(fullContent);
  saveAndDownloadBytes(bytes, fileName, mimeType);
}

void saveAndDownloadBytes(List<int> bytes, String fileName, String mimeType) {
  final uint8 = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final jsArray = [uint8.toJS].toJS;
  final blob = web.Blob(
    jsArray,
    web.BlobPropertyBag(type: mimeType),
  );
  
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
