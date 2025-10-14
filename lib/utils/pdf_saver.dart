import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Conditional imports
import 'pdf_saver_stub.dart'
    if (dart.library.html) 'pdf_saver_web.dart'
    if (dart.library.io) 'pdf_saver_io.dart';

abstract class PdfSaver {
  static Future<void> savePdf(Uint8List pdfBytes, String fileName) async {
    return savePdfImplementation(pdfBytes, fileName);
  }
}