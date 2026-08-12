import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfReportTheme {
  static pw.ThemeData? _theme;

  static Future<pw.ThemeData> load() async {
    final cachedTheme = _theme;
    if (cachedTheme != null) return cachedTheme;

    final fontData = await rootBundle.load('assets/fonts/ArialUnicode.ttf');
    final font = pw.Font.ttf(fontData);
    return _theme = pw.ThemeData.withFont(
      base: font,
      bold: font,
      fontFallback: [font],
    );
  }
}
