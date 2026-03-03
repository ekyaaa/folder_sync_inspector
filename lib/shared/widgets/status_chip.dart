import 'package:flutter/material.dart';
import '../../features/folder_compare/models/compare_result.dart';

/// Colored status chip for file comparison status.
class StatusChip extends StatelessWidget {
  final FileStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color foregroundColor;
    String label;
    IconData icon;

    switch (status) {
      case FileStatus.match:
        backgroundColor = const Color(0xFF2E7D32).withValues(alpha: 0.15);
        foregroundColor = colorScheme.brightness == Brightness.dark
            ? const Color(0xFF81C784)
            : const Color(0xFF2E7D32);
        label = 'Match';
        icon = Icons.check_circle_outline_rounded;
        break;
      case FileStatus.different:
        backgroundColor = const Color(0xFFE65100).withValues(alpha: 0.15);
        foregroundColor = colorScheme.brightness == Brightness.dark
            ? const Color(0xFFFFB74D)
            : const Color(0xFFE65100);
        label = 'Different';
        icon = Icons.compare_arrows_rounded;
        break;
      case FileStatus.missing:
        backgroundColor = const Color(0xFFC62828).withValues(alpha: 0.15);
        foregroundColor = colorScheme.brightness == Brightness.dark
            ? const Color(0xFFEF9A9A)
            : const Color(0xFFC62828);
        label = 'Missing in B';
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Presence chip for git check (Yes/No).
class PresenceChip extends StatelessWidget {
  final bool present;

  const PresenceChip({super.key, required this.present});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = present
        ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
        : const Color(0xFFC62828).withValues(alpha: 0.15);
    final foregroundColor = present
        ? (colorScheme.brightness == Brightness.dark
              ? const Color(0xFF81C784)
              : const Color(0xFF2E7D32))
        : (colorScheme.brightness == Brightness.dark
              ? const Color(0xFFEF9A9A)
              : const Color(0xFFC62828));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            present
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            size: 14,
            color: foregroundColor,
          ),
          const SizedBox(width: 4),
          Text(
            present ? 'Yes' : 'No',
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
