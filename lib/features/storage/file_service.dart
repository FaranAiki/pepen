import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../editor/models/field_block.dart';

class FileService {
  static Future<void> saveAsPepen(String filePath, List<FieldBlock> blocks, String globalFont) async {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('pepen', nest: () {
      builder.element('settings', nest: () {
        builder.element('globalFont', nest: globalFont);
      });
      builder.element('fields', nest: () {
        for (var block in blocks) {
          builder.element('field', nest: () {
            builder.attribute('id', block.id);
            builder.element('content', nest: () {
              builder.cdata(jsonEncode(block.controller.document.toDelta().toJson()));
            });
          });
        }
      });
    });

    final document = builder.buildDocument();
    final file = File(filePath);
    await file.writeAsString(document.toXmlString(pretty: true));
  }

  static Future<void> saveAsTxt(String filePath, List<FieldBlock> blocks) async {
    final buffer = StringBuffer();
    for (var i = 0; i < blocks.length; i++) {
      buffer.write(blocks[i].controller.document.toPlainText());
      if (i < blocks.length - 1) {
        buffer.writeln();
      }
    }
    final file = File(filePath);
    await file.writeAsString(buffer.toString());
  }

  static Map<String, dynamic>? loadPepen(String content) {
    try {
      final document = XmlDocument.parse(content);
      final pepen = document.getElement('pepen');
      if (pepen == null) return null;

      final settings = pepen.getElement('settings');
      final globalFont = settings?.getElement('globalFont')?.innerText ?? 'Roboto';

      final fieldsElement = pepen.getElement('fields');
      final fieldBlocks = <Document>[];

      if (fieldsElement != null) {
        for (var fieldNode in fieldsElement.findElements('field')) {
          final contentNode = fieldNode.getElement('content');
          if (contentNode != null) {
            final deltaJson = jsonDecode(contentNode.innerText);
            fieldBlocks.add(Document.fromJson(deltaJson));
          }
        }
      }

      return {
        'globalFont': globalFont,
        'documents': fieldBlocks,
      };
    } catch (e) {
      return null;
    }
  }
}
