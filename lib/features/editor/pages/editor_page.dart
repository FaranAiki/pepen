import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
          child: const SettingsPage(),
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final editor = context.read<EditorProvider>();
    final bytes = await PdfExportService.exportToPdf(editor.blocks);
    
    String? outputFile = await picker.FilePicker.saveFile(
      dialogTitle: 'Save PDF',
      fileName: 'document.pdf',
      type: picker.FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputFile != null) {
      if (!outputFile.endsWith('.pdf')) outputFile += '.pdf';
      final file = File(outputFile);
      await file.writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Saved')));
      }
    }
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
          ),
          child: SafeArea(
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.description, color: Colors.blue, size: 24),
                const SizedBox(width: 24),
                _buildMenuBar(context, l10n),
              ],
            ),
          ),
        ),
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
                    buttonOptions: const quill.QuillSimpleToolbarButtonOptions(
                      base: quill.QuillToolbarBaseButtonOptions(
                        iconSize: 20,
                      ),
                    ),
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
                      margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 80),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: ThemeData(
                          brightness: Brightness.light,
                          textTheme: GoogleFonts.getTextTheme('Roboto').apply(
                            bodyColor: Colors.black,
                            displayColor: Colors.black,
                          ),
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
                            const SizedBox(height: 50),
                            _buildAddPageButton(context, l10n),
                          ],
                        ),
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

  Widget _buildMenuBar(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        _buildMenuButton(
          context,
          'File',
          [
            PopupMenuItem(
              onTap: () => _openFile(context, l10n),
              child: Text(l10n.translate('open')),
            ),
            PopupMenuItem(
              onTap: () => _saveAsPepen(context, l10n),
              child: Text(l10n.translate('save_as_pepn')),
            ),
            PopupMenuItem(
              onTap: () => _saveAsTxt(context, l10n),
              child: Text(l10n.translate('save_as_txt')),
            ),
            PopupMenuItem(
              onTap: () => _exportPdf(context),
              child: Text(l10n.translate('export_pdf')),
            ),
          ],
        ),
        _buildMenuButton(
          context,
          'Settings',
          [
            PopupMenuItem(
              onTap: () => _showSettings(context),
              child: Text(l10n.translate('settings')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, List<PopupMenuEntry<dynamic>> items) {
    return PopupMenuButton<dynamic>(
      offset: const Offset(0, 36),
      itemBuilder: (context) => items,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16, // Appropriately sized menu text
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildAddPageButton(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        children: [
          const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.read<EditorProvider>().addBlock(),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 20, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    l10n.translate('add_section'),
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
