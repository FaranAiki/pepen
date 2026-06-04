import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import '../providers/editor_provider.dart';
import '../widgets/block_field_widget.dart';
import '../../../core/settings_provider.dart';
import '../../../core/app_localizations.dart';
import '../../storage/file_service.dart';
import '../../settings/pages/settings_page.dart';

import '../../storage/pdf_export_service.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  void _exportPdf(BuildContext context) {
    final editor = context.read<EditorProvider>();
    PdfExportService.exportToPdf(editor.blocks);
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: const SettingsPage(),
        ),
      ),
    );
  }

  Future<void> _saveAsPepen(BuildContext context, AppLocalizations l10n) async {
    try {
      final editor = context.read<EditorProvider>();
      final settings = context.read<SettingsProvider>();
      String? outputFile = await picker.FilePicker.saveFile(
        dialogTitle: l10n.translate('save_as_pepn'),
        fileName: 'document.pepn',
        type: picker.FileType.custom,
        allowedExtensions: ['pepn'],
      );

      if (outputFile != null) {
        if (!outputFile.endsWith('.pepn')) outputFile += '.pepn';
        await FileService.saveAsPepen(outputFile, editor.blocks, settings.globalFont);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translate('save_as_pepn'))));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
    }
  }

  Future<void> _saveAsTxt(BuildContext context, AppLocalizations l10n) async {
    try {
      final editor = context.read<EditorProvider>();
      String? outputFile = await picker.FilePicker.saveFile(
        dialogTitle: l10n.translate('save_as_txt'),
        fileName: 'document.txt',
        type: picker.FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (outputFile != null) {
        if (!outputFile.endsWith('.txt')) outputFile += '.txt';
        await FileService.saveAsTxt(outputFile, editor.blocks);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translate('save_as_txt'))));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
    }
  }

  Future<void> _openFile(BuildContext context, AppLocalizations l10n) async {
    try {
      final editor = context.read<EditorProvider>();
      final settings = context.read<SettingsProvider>();
      picker.FilePickerResult? result = await picker.FilePicker.pickFiles(
        type: picker.FileType.custom,
        allowedExtensions: ['pepn', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        if (result.files.single.extension == 'pepn') {
          final data = FileService.loadPepen(content);
          if (data != null) {
            editor.clearAll();
            final documents = data['documents'] as List<quill.Document>;
            for (var i = 0; i < documents.length; i++) {
              if (i == 0) {
                editor.blocks[0].controller.document = documents[0];
              } else {
                editor.addBlock(document: documents[i]);
              }
            }
            settings.setGlobalFont(data['globalFont']);
          }
        } else {
          editor.clearAll();
          editor.blocks[0].controller.document = quill.Document()..insert(0, content);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('app_title')),
        elevation: 0,
        backgroundColor: Theme.of(context).canvasColor,
        actions: [
          IconButton(icon: const Icon(Icons.open_in_browser), onPressed: () => _openFile(context, l10n), tooltip: l10n.translate('open')),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'pepn') _saveAsPepen(context, l10n);
              if (value == 'txt') _saveAsTxt(context, l10n);
              if (value == 'pdf') _exportPdf(context);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'pepn', child: Text(l10n.translate('save_as_pepn'))),
              PopupMenuItem(value: 'txt', child: Text(l10n.translate('save_as_txt'))),
              PopupMenuItem(value: 'pdf', child: Text(l10n.translate('export_pdf'))),
            ],
            icon: const Icon(Icons.save),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Global Toolbar
          Selector<EditorProvider, String?>(
            selector: (_, provider) => provider.activeBlockId,
            builder: (context, activeBlockId, child) {
              final provider = context.read<EditorProvider>();
              final activeBlock = provider.activeBlock;
              if (activeBlock == null) return const SizedBox.shrink();
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                ),
                child: quill.QuillSimpleToolbar(
                  controller: activeBlock.controller,
                  config: quill.QuillSimpleToolbarConfig(
                    embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                    showFontFamily: true,
                    showFontSize: true,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: false,
                    showColorButton: true,
                    showBackgroundColorButton: true,
                    showListNumbers: true,
                    showListBullets: true,
                    showClearFormat: true,
                    showAlignmentButtons: true,
                    multiRowsDisplay: false,
                  ),
                ),
              );
            },
          ),
          // Content Area
          Expanded(
            child: Selector<EditorProvider, int>(
              selector: (_, provider) => provider.blocks.length,
              builder: (context, blockCount, child) {
                final provider = context.read<EditorProvider>();
                return SingleChildScrollView(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 850),
                      margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light 
                          ? Colors.white 
                          : Colors.grey[900],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...provider.blocks.asMap().entries.map((entry) {
                            final index = entry.key;
                            final block = entry.value;
                            return BlockFieldWidget(
                              key: ValueKey(block.id),
                              block: block,
                              onRemove: () => provider.removeBlock(block.id),
                              showRemove: blockCount > 1,
                              isFirst: index == 0,
                            );
                          }),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => provider.addBlock(),
                              icon: const Icon(Icons.add),
                              label: Text(l10n.translate('add_section')),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
