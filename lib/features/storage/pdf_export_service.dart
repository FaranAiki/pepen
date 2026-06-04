import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../editor/models/field_block.dart';

class PdfExportService {
  static Future<Uint8List> exportToPdf(List<FieldBlock> blocks) async {
    final pdf = pw.Document();
    
    // Load a font that supports Unicode (Roboto)
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    List<pw.Widget> widgets = [];

    for (var block in blocks) {
      if (block.type == BlockType.text) {
        final delta = block.controller.document.toDelta();
        
        List<pw.InlineSpan> spans = [];
        
        for (var op in delta.toList()) {
          if (op.isInsert) {
            if (op.data is String) {
              final text = op.data as String;
              if (text == '\n') continue;
              
              final attributes = op.attributes ?? {};
              spans.add(pw.TextSpan(
                text: text,
                style: pw.TextStyle(
                  font: font,
                  fontBold: boldFont,
                  fontItalic: italicFont,
                  fontWeight: attributes['bold'] == true ? pw.FontWeight.bold : pw.FontWeight.normal,
                  fontStyle: attributes['italic'] == true ? pw.FontStyle.italic : pw.FontStyle.normal,
                  decoration: attributes['underline'] == true ? pw.TextDecoration.underline : pw.TextDecoration.none,
                  fontSize: 12,
                ),
              ));
            } else if (op.data is Map) {
              final mapData = op.data as Map;
              if (mapData.containsKey('formula')) {
                final formula = mapData['formula'] as String;
                spans.add(pw.TextSpan(
                  text: formula,
                  style: pw.TextStyle(
                    font: italicFont,
                    color: PdfColors.blue900,
                    fontSize: 12,
                  ),
                ));
              }
            }
          }
        }
        
        if (spans.isNotEmpty) {
          widgets.add(pw.RichText(
            text: pw.TextSpan(children: spans),
          ));
        } else {
          // Fallback to plain text if span logic fails, but filter out the object replacement char
          final plainText = block.controller.document.toPlainText().replaceAll('\ufffc', '');
          if (plainText.trim().isNotEmpty) {
            widgets.add(pw.Paragraph(
              text: plainText,
              style: pw.TextStyle(font: font, fontSize: 12),
            ));
          }
        }
      } else if (block.type == BlockType.image) {
        Uint8List? imageBytes;
        if (block.base64Data != null) {
          imageBytes = base64Decode(block.base64Data!);
        } else if (block.assetPath != null) {
          final imageFile = File(block.assetPath!);
          if (imageFile.existsSync()) {
            imageBytes = imageFile.readAsBytesSync();
          }
        }

        if (imageBytes != null) {
          try {
            final image = pw.MemoryImage(imageBytes);
            widgets.add(pw.Center(
              child: pw.Image(image, height: 400),
            ));
          } catch (e) {
            widgets.add(pw.Text('[Error loading image]', style: pw.TextStyle(font: font)));
          }
        }
      } else {
        widgets.add(pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          child: pw.Text('[${block.type.name.toUpperCase()}: ${block.fileName}]', style: pw.TextStyle(font: font)),
        ));
      }
      widgets.add(pw.SizedBox(height: 10));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => widgets,
      ),
    );

    return await pdf.save();
  }
}
