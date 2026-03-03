import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

/// A styled folder picker field with display of selected path.
class FolderPickerField extends StatelessWidget {
  final String label;
  final String? selectedPath;
  final IconData icon;
  final ValueChanged<String> onSelected;

  const FolderPickerField({
    super.key,
    required this.label,
    this.selectedPath,
    this.icon = Icons.folder_outlined,
    required this.onSelected,
  });

  Future<void> _pickFolder() async {
    final directoryPath = await getDirectoryPath(confirmButtonText: 'Select');
    if (directoryPath != null) {
      onSelected(directoryPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPath = selectedPath != null && selectedPath!.isNotEmpty;

    return InkWell(
      onTap: _pickFolder,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPath
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: hasPath
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (hasPath) ...[
                    const SizedBox(height: 2),
                    Text(
                      selectedPath!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ] else
                    Text(
                      'Click to select folder…',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
