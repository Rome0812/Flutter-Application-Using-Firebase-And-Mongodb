import 'package:flutter/material.dart';
import '../utils/loading.dart';
class ArticleDialogue extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> payload, BuildContext ctx) onSave;
 
  const ArticleDialogue({
    super.key,
    required this.onSave,
  });
 
  @override
  State<ArticleDialogue> createState() => _ArticleDialogueState();
}
 
class _ArticleDialogueState extends State<ArticleDialogue> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final contentController = TextEditingController();
  bool isActive = true;
 
  List<String> _toList(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
 
  Future<void> _handleSave(BuildContext ctx) async {
    LoadingOverlay.show(context, message: "Uploading article...");
    if (!formKey.currentState!.validate()) return;
     
    final payload = {
      'title': titleController.text.trim(),
      'name': authorController.text.trim(),
      'content': _toList(contentController.text),
      'isActive': isActive,
    };
 
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
 
    try {
      await widget.onSave(payload, ctx);
    } catch (e) {
      // Handle error if needed
    } finally {
      LoadingOverlay.hide(context);
      Navigator.of(context).pop();  // Close loading dialog
       
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Article'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: authorController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Author / Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contentController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Content (one per line or comma-separated)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null) return 'At least one content item';
                  final items = v
                      .trim()
                      .split(RegExp(r'[\n,]'))
                      .where((s) => s.trim().isNotEmpty)
                      .toList();
                  return items.isEmpty ? 'At least one content item' : null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                activeTrackColor: Colors.green,
                value: isActive,
                onChanged: (val) => setState(() => isActive = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => _handleSave(context),
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    );
  }
}
 