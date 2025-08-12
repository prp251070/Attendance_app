import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<File?> downloadAndCacheImage(String imageUrl, String filename) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory(); // 👈 This is where your image is stored
      final file = File('${dir.path}/$filename');

      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      print('Failed to download image: ${response.statusCode}');
    }
  } catch (e) {
    print('Error downloading image: $e');
  }

  return null;
}