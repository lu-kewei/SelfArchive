import 'package:flutter/material.dart';
import '../../../../core/theme/theme_pack.dart';

class TotemInitializationOverlay extends StatefulWidget {
  final ThemePack theme;
  final VoidCallback? onDismiss;
  final Function(String name, int styleIndex) onCreate;
  final String? initialName;
  final int? initialStyleIndex;
  final bool isEditing;

  const TotemInitializationOverlay({
    super.key,
    required this.theme,
    required this.onCreate,
    this.onDismiss,
    this.initialName,
    this.initialStyleIndex,
    this.isEditing = false,
  });

  @override
  State<TotemInitializationOverlay> createState() =>
      _TotemInitializationOverlayState();
}

class _TotemInitializationOverlayState
    extends State<TotemInitializationOverlay> {
  late TextEditingController _nameController;
  late int _selectedStyleIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    // Default to cream (index 0) if not editing, or provided index
    _selectedStyleIndex = widget.initialStyleIndex ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name =
        _nameController.text.trim().isEmpty ? "我" : _nameController.text.trim();
    widget.onCreate(name, _selectedStyleIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent background
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              color: Colors.black54,
            ),
          ),
        ),
        // Content
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isEditing ? "修改图腾" : "创建图腾",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "这面墙的核心对象名称",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "默认为“我”",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                    autofocus: !widget.isEditing,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "选择样式",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      widget.theme.totemAssets.length,
                      (index) {
                        final isSelected = _selectedStyleIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedStyleIndex = index;
                            });
                            // Automatically submit on selection if creating
                            // Or maybe wait for user to confirm?
                            // Requirement: "User does NOT need to click extra confirm button, as long as complete name input AND stay or click any style automatically create"
                            // If we are editing, we might want to let them explore.
                            // But for init flow, clicking style triggers creation.
                            // Let's support both: click style -> update selection -> if name is ready -> submit.
                            // But wait, user might want to click to SEE selection then confirm?
                            // "User does NOT need to click extra confirm button... click any style automatically create"
                            // This implies clicking style IS the confirm action.

                            // Let's do this:
                            // Update selection UI first (maybe delay slightly?)
                            // No, if clicking style creates it, we can just call submit.
                            _submit();
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: isSelected
                                  ? Border.all(
                                      color: widget.theme.accentColor, width: 3)
                                  : null,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                widget.theme.totemAssets[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("完成"),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
