import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> savePdfImplementation(Uint8List pdfBytes, String fileName) async {
  // Get the appropriate directory
  Directory? directory;
  
  if (Platform.isAndroid) {
    // On Android, save to Downloads directory
    directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      // Fallback to app's external storage directory
      directory = await getExternalStorageDirectory();
    }
  } else if (Platform.isIOS) {
    // On iOS, save to Documents directory
    directory = await getApplicationDocumentsDirectory();
  } else {
    // For desktop platforms
    directory = await getDownloadsDirectory();
  }

  if (directory == null) {
    throw Exception('Could not find suitable directory');
  }

  // Create the file path
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);

  // Write the PDF bytes to file
  await file.writeAsBytes(pdfBytes);
}