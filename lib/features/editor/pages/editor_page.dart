import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../models/field_block.dart';
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
    final bytes = await PdfExportService.exportToPdf(editor.pages.expand((p) => p.blocks).toList());
    
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
        await FileService.saveAsPepen(outputFile, editor.pages, settings.globalFont);
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
        await FileService.saveAsTxt(outputFile, editor.pages);
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

        if (result.files.single.extension == 'pepn') {
          final bytes = await file.readAsBytes();
          final data = FileService.loadPepen(bytes);
          if (data != null) {
            editor.clearAll();
            final loadedPages = data['pages'] as List<PageModel>;
            
            editor.clearAll();
            for (var i = 0; i < loadedPages.length; i++) {
              if (i > 0) editor.addPage();
              for (var block in loadedPages[i].blocks) {
                if (i == 0 && block == loadedPages[0].blocks.first && editor.pages[0].blocks.length == 1) {
                   editor.pages[0].blocks[0].controller.document = block.controller.document;
                } else {
                   editor.addBlockToPage(i, 
                    document: block.controller.document, 
                    type: block.type, 
                    base64Data: block.base64Data, 
                    fileName: block.fileName
                   );
                }
              }
            }
            settings.setGlobalFont(data['globalFont']);
          }
        } else {
          final content = await file.readAsString();
          editor.clearAll();
          editor.pages[0].blocks[0].controller.document = quill.Document()..insert(0, content);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open error: $e')));
      }
    }
  }

  Future<void> _addTypedBlock(BuildContext context, int pageIndex, BlockType type) async {
    final editor = context.read<EditorProvider>();
    
    if (type == BlockType.text) {
      editor.addBlockToPage(pageIndex, type: type);
      return;
    }

    picker.FileType pickerType;
    switch (type) {
      case BlockType.image: pickerType = picker.FileType.image; break;
      case BlockType.audio: pickerType = picker.FileType.audio; break;
      case BlockType.file: pickerType = picker.FileType.any; break;
      default: pickerType = picker.FileType.any;
    }

    final result = await picker.FilePicker.pickFiles(type: pickerType);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      String? base64;
      if (type == BlockType.image) {
        base64 = base64Encode(await file.readAsBytes());
      }
      editor.addBlockToPage(pageIndex, type: type, assetPath: file.path, base64Data: base64, fileName: fileName);
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
          const _EditorToolbar(),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: Consumer<EditorProvider>(
                builder: (context, provider, child) {
                  return ListView.builder(
                    itemCount: provider.pages.length + 1,
                    cacheExtent: 1000,
                    itemBuilder: (context, index) {
                      if (index == provider.pages.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: InkWell(
                              onTap: () => provider.addPage(),
                              borderRadius: BorderRadius.circular(4),
                              child: _buildAddButtonUI(context, 'Add New Page'),
                            ),
                          ),
                        );
                      }
                      final page = provider.pages[index];
                      return _PageWidget(
                        key: ValueKey(page.id),
                        page: page,
                        pageIndex: index,
                        l10n: l10n,
                        onAddBlock: (type) => _addTypedBlock(context, index, type),
                      );
                    },
                  );
                },
              ),
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
            PopupMenuItem(onTap: () => _openFile(context, l10n), child: Text(l10n.translate('open'))),
            PopupMenuItem(onTap: () => _saveAsPepen(context, l10n), child: Text(l10n.translate('save_as_pepn'))),
            PopupMenuItem(onTap: () => _saveAsTxt(context, l10n), child: Text(l10n.translate('save_as_txt'))),
            PopupMenuItem(onTap: () => _exportPdf(context), child: Text(l10n.translate('export_pdf'))),
          ],
        ),
        _buildMenuButton(
          context,
          'Settings',
          [
            PopupMenuItem(onTap: () => _showSettings(context), child: Text(l10n.translate('settings'))),
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
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar();

  @override
  Widget build(BuildContext context) {
    return Selector<EditorProvider, String?>(
      selector: (_, provider) => provider.activeBlockId,
      builder: (context, activeBlockId, child) {
        final provider = context.read<EditorProvider>();
        final activeBlock = provider.activeBlock;
        if (activeBlock == null || activeBlock.type != BlockType.text) {
          return const SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
          ),
          child: quill.QuillSimpleToolbar(
            controller: activeBlock.controller,
            config: const quill.QuillSimpleToolbarConfig(
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
              buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                base: quill.QuillToolbarBaseButtonOptions(
                  iconSize: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageWidget extends StatelessWidget {
  final PageModel page;
  final int pageIndex;
  final AppLocalizations l10n;
  final Function(BlockType) onAddBlock;

  const _PageWidget({
    super.key,
    required this.page,
    required this.pageIndex,
    required this.l10n,
    required this.onAddBlock,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EditorProvider>();
    return Center(
      child: Container(
        width: 800,
        constraints: const BoxConstraints(minHeight: 1131),
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.fromLTRB(80, 80, 80, 40),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
              ...page.blocks.asMap().entries.map((entry) {
                final block = entry.value;
                return BlockFieldWidget(
                  key: ValueKey(block.id),
                  block: block,
                  onRemove: () => provider.removeBlock(block.id),
                  showRemove: true,
                  isFirst: pageIndex == 0 && entry.key == 0,
                );
              }),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 12),
                    PopupMenuButton<BlockType>(
                      onSelected: onAddBlock,
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: BlockType.text, child: Row(children: [Icon(Icons.text_fields), SizedBox(width: 8), Text('Text')])),
                        const PopupMenuItem(value: BlockType.image, child: Row(children: [Icon(Icons.image), SizedBox(width: 8), Text('Image')])),
                        const PopupMenuItem(value: BlockType.audio, child: Row(children: [Icon(Icons.audiotrack), SizedBox(width: 8), Text('Audio')])),
                        const PopupMenuItem(value: BlockType.file, child: Row(children: [Icon(Icons.insert_drive_file), SizedBox(width: 8), Text('File')])),
                      ],
                      child: _buildAddButtonUI(context, l10n.translate('add_section')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildAddButtonUI(BuildContext context, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.add, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    ),
  );
}
