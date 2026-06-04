import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../editor/models/field_block.dart';

class PdfExportService {
  static Future<void> exportToPdf(List<FieldBlock> blocks) async {
    final pdf = pw.Document();

    for (var block in blocks) {
      final text = block.controller.document.toPlainText();
      if (text.trim().isEmpty) continue;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Text(text); // Simple text export for now
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
