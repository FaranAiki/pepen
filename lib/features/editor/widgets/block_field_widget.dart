import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';
import '../models/field_block.dart';
import '../providers/editor_provider.dart';
import '../../../core/app_localizations.dart';

class BlockFieldWidget extends StatefulWidget {
  final FieldBlock block;
  final VoidCallback onRemove;
  final bool showRemove;
  final bool isFirst;

  const BlockFieldWidget({
    super.key,
    required this.block,
    required this.onRemove,
    this.showRemove = true,
    this.isFirst = false,
  });

  @override
  State<BlockFieldWidget> createState() => _BlockFieldWidgetState();
}

class _BlockFieldWidgetState extends State<BlockFieldWidget> {
  late final FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      context.read<EditorProvider>().setActiveBlock(widget.block.id);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Only show labels/remove when hovered
            AnimatedOpacity(
              opacity: _isHovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  Text(
                    widget.isFirst ? l10n.translate('start_of_document') : l10n.translate('new_section'),
                    style: TextStyle(
                      fontSize: 12, // Slightly larger label
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                  const Spacer(),
                  if (widget.showRemove)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: widget.onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove',
                    ),
                ],
              ),
            ),
            QuillEditor(
              controller: widget.block.controller,
              scrollController: ScrollController(),
              focusNode: _focusNode,
              config: QuillEditorConfig(
                autoFocus: false,
                expands: false,
                padding: EdgeInsets.zero,
                placeholder: l10n.translate('type_here'),
                embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                customStyles: DefaultStyles(
                  paragraph: DefaultTextBlockStyle(
                    const TextStyle(color: Colors.black, fontSize: 16, height: 1.5), // Standard reading size
                    const HorizontalSpacing(0, 0),
                    const VerticalSpacing(0, 0),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
