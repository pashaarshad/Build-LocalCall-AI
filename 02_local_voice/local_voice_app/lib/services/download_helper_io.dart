import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<String> downloadAudioFile({
  required String url,
  required String filename,
  List<int>? bytes,
}) async {
  List<int> fileBytes = bytes ?? [];

  if (fileBytes.isEmpty) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        fileBytes = response.bodyBytes;
      } else {
        throw Exception('Download failed with status ${response.statusCode}');
      }
    } else {
      // Local file path
      final localFile = File(url);
      if (await localFile.exists()) {
        fileBytes = await localFile.readAsBytes();
      }
    }
  }

  Directory? targetDir;
  try {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        targetDir = downloadDir;
      }
    }
  } catch (_) {}

  targetDir ??= await getApplicationDocumentsDirectory();

  final cleanName = filename.endsWith('.mp3') ? filename : '$filename.mp3';
  final file = File('${targetDir.path}/$cleanName');
  await file.writeAsBytes(fileBytes);

  return file.path;
}
