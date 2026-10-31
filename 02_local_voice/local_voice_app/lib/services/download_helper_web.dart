// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<String> downloadAudioFile({
  required String url,
  required String filename,
  List<int>? bytes,
}) async {
  String downloadUrl = url;
  if (bytes != null && bytes.isNotEmpty) {
    final blob = html.Blob([bytes], 'audio/mpeg');
    downloadUrl = html.Url.createObjectUrlFromBlob(blob);
  }

  final anchor = html.AnchorElement(href: downloadUrl)
    ..target = '_blank'
    ..download = filename.endsWith('.mp3') ? filename : '$filename.mp3';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  return 'Downloads/$filename';
}
