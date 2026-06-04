import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../editor/models/field_block.dart';
import '../../core/compression_service.dart';

class FileService {
  static Future<void> saveAsPepen(String filePath, List<PageModel> pages, String globalFont) async {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('pepen', nest: () {
      builder.element('settings', nest: () {
        builder.element('globalFont', nest: globalFont);
      });
      builder.element('pages', nest: () {
        for (var page in pages) {
          builder.element('page', nest: () {
            builder.attribute('id', page.id);
            builder.element('fields', nest: () {
              for (var block in page.blocks) {
                builder.element('field', nest: () {
                  builder.attribute('id', block.id);
                  builder.attribute('type', block.type.name);
                  if (block.base64Data != null) {
                    builder.element('metadata', nest: block.base64Data);
                  }
                  if (block.fileName != null) {
                    builder.attribute('fileName', block.fileName!);
                  }
                  builder.element('content', nest: () {
                    builder.cdata(jsonEncode(block.controller.document.toDelta().toJson()));
                  });
                });
              }
            });
          });
        }
      });
    });

    final xmlContent = builder.buildDocument().toXmlString(pretty: true);
    final compressedData = CompressionService.compress(xmlContent);
    final file = File(filePath);
    await file.writeAsBytes(compressedData);
  }

  static Future<void> saveAsTxt(String filePath, List<PageModel> pages) async {
    final buffer = StringBuffer();
    for (var page in pages) {
      for (var block in page.blocks) {
        if (block.type == BlockType.text) {
          buffer.write(block.controller.document.toPlainText());
        } else {
          buffer.write('[${block.type.name.toUpperCase()}: ${block.fileName}]');
        }
        buffer.writeln();
      }
      buffer.writeln('--- Page Break ---');
      buffer.writeln();
    }
    final file = File(filePath);
    await file.writeAsString(buffer.toString());
  }

  static Map<String, dynamic>? loadPepen(List<int> bytes) {
    try {
      final xmlContent = CompressionService.decompress(bytes);
      final document = XmlDocument.parse(xmlContent);
      final pepen = document.getElement('pepen');
      if (pepen == null) return null;

      final settings = pepen.getElement('settings');
      final globalFont = settings?.getElement('globalFont')?.innerText ?? 'Roboto';

      final pagesElement = pepen.getElement('pages');
      final loadedPages = <PageModel>[];

      if (pagesElement != null) {
        for (var pageNode in pagesElement.findElements('page')) {
          final fieldsElement = pageNode.getElement('fields');
          final blocks = <FieldBlock>[];
          if (fieldsElement != null) {
            for (var fieldNode in fieldsElement.findElements('field')) {
              final id = fieldNode.getAttribute('id');
              final typeAttr = fieldNode.getAttribute('type');
              final fileName = fieldNode.getAttribute('fileName');
              final type = BlockType.values.firstWhere((e) => e.name == typeAttr, orElse: () => BlockType.text);
              final metadata = fieldNode.getElement('metadata')?.innerText;
              
              final contentNode = fieldNode.getElement('content');
              if (contentNode != null) {
                final deltaJson = jsonDecode(contentNode.innerText);
                blocks.add(FieldBlock(
                  id: id,
                  document: Document.fromJson(deltaJson),
                  type: type,
                  base64Data: metadata,
                  fileName: fileName,
                ));
              }
            }
          }
          loadedPages.add(PageModel(id: pageNode.getAttribute('id'), blocks: blocks));
        }
      }

      return {
        'globalFont': globalFont,
        'pages': loadedPages,
      };
    } catch (e) {
      return null;
    }
  }
}
