import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// A single unbundled consent purpose: icon + title + explanation + a switch.
/// Shared by the gate screen and the settings Data & Privacy screen so the copy
/// and affordance stay identical (a withdrawal must be as easy as the grant).
class ConsentChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const ConsentChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Z.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? Z.brand : Z.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Z.brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: Z.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Z.text)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: const TextStyle(
                          fontSize: 13, color: Z.textMuted, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: Colors.white,
              activeTrackColor: Z.brand,
            ),
          ],
        ),
      ),
    );
  }
}
