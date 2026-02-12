import 'dart:async';
import 'package:flutter/material.dart';
import '../../scene/models/node_entity.dart';

class EditorSheet extends StatefulWidget {
  final NodeEntity node;
  final Function(String content, List<String> tags) onSave;
  final VoidCallback onDelete;

  const EditorSheet({
    super.key,
    required this.node,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<EditorSheet> {
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late List<String> _tags;
  Timer? _autoSaveTimer;
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.node.content);
    _tagController = TextEditingController();
    _tags = List<String>.from(widget.node.tags ?? []);

    // Auto-save on focus lost
    _contentFocusNode.addListener(() {
      if (!_contentFocusNode.hasFocus) {
        _triggerAutoSave();
      }
    });

    // Auto-save debounce on change
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    // Final save on dispose
    widget.onSave(_contentController.text, _tags);

    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    _tagController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (_autoSaveTimer?.isActive ?? false) _autoSaveTimer!.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 1), _triggerAutoSave);
  }

  void _triggerAutoSave() {
    if (!mounted) return;
    widget.onSave(_contentController.text, _tags);
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
      _triggerAutoSave();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _triggerAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85, // Open almost full screen for better editing
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: widget.onDelete,
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('删除'),
                    ),
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        widget.onSave(_contentController.text, _tags);
                        Navigator.pop(context); // Explicit save closes
                      },
                      child: const Text('完成',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Type Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.node.type.toString().split('.').last,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_autoSaveTimer?.isActive ?? false)
                          const Text('保存中...',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey))
                        else
                          const Text('已保存',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Content Input
                    TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      maxLines: null, // Supports multiline
                      autofocus: true, // Auto focus when opened
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      decoration: const InputDecoration(
                        hintText: '输入内容...',
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 48), // Add padding for bottom
                    // Tags Section
                    const Text(
                      '标签 / 关联',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._tags.map((tag) => Chip(
                              label: Text(tag),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removeTag(tag),
                              backgroundColor: Colors.blue.shade50,
                              labelStyle:
                                  TextStyle(color: Colors.blue.shade900),
                            )),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _tagController,
                            decoration: const InputDecoration(
                              hintText: '+ 添加标签',
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                      ],
                    ),
                    // Add extra space at bottom to avoid keyboard overlap issues
                    SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom + 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
