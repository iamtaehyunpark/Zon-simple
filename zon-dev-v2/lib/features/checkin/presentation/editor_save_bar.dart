import 'package:flutter/material.dart';

/// Bottom save bar shared by the check-in and stamp editors: a full-width
/// button respecting the safe-area inset, disabled until [enabled].
class EditorSaveBar extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onSave;
  const EditorSaveBar({
    super.key,
    required this.label,
    required this.enabled,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: enabled ? onSave : null,
          child: Text(label),
        ),
      ),
    );
  }
}
