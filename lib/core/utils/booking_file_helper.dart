import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class BookingFileHelper {
  /// Saves binary bytes (e.g. PDF ticket/invoice) to a local temp file and attempts to open it.
  static Future<String> saveAndOpenDocument({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final file = File('${dir.path}/$sanitizedName');
      await file.writeAsBytes(bytes, flush: true);

      final uri = Uri.file(file.path);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (launchError) {
        debugPrint('[BookingFileHelper] Error launching file URL: $launchError');
      }

      return file.path;
    } catch (e) {
      debugPrint('[BookingFileHelper] Error saving file: $e');
      rethrow;
    }
  }
}
