import 'package:flutter/material.dart';
import '../models/compare_result.dart';
import '../../../shared/widgets/status_chip.dart';
import 'diff_viewer.dart';

/// Full-width flex table for folder compare results with search, filter, and diff modal.
class CompareTable extends StatelessWidget {
  final List<FileCompareEntry> entries;
  final FileStatus? activeFilter;
  final String searchQuery;
  final String folderAPath;
  final String folderBPath;
  final ValueChanged<FileStatus?> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  const CompareTable({
    super.key,
    required this.entries,
    this.activeFilter,
    required this.searchQuery,
    required this.folderAPath,
    required this.folderBPath,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  String _formatSize(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & filter bar
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search files…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _FilterChip(
              label: 'All',
              selected: activeFilter == null,
              onTap: () => onFilterChanged(null),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Match',
              selected: activeFilter == FileStatus.match,
              onTap: () => onFilterChanged(FileStatus.match),
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Different',
              selected: activeFilter == FileStatus.different,
              onTap: () => onFilterChanged(FileStatus.different),
              color: const Color(0xFFE65100),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Missing',
              selected: activeFilter == FileStatus.missing,
              onTap: () => onFilterChanged(FileStatus.missing),
              color: const Color(0xFFC62828),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table
        if (entries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No files match the current filter.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text('Status', style: _headerStyle),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Relative Path', style: _headerStyle),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text('Size (A)', style: _headerStyle),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text('Size (B)', style: _headerStyle),
                      ),
                      SizedBox(
                        width: 150,
                        child: Text('Modified (A)', style: _headerStyle),
                      ),
                      SizedBox(
                        width: 150,
                        child: Text('Modified (B)', style: _headerStyle),
                      ),
                    ],
                  ),
                ),
                // Table rows
                ...entries.map((entry) {
                  final isDifferent = entry.status == FileStatus.different;
                  return InkWell(
                    onTap: isDifferent
                        ? () => DiffDialog.show(
                            context,
                            relativePath: entry.relativePath,
                            folderAPath: folderAPath,
                            folderBPath: folderBPath,
                          )
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: StatusChip(status: entry.status),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Tooltip(
                              message: entry.relativePath,
                              child: Text(
                                entry.relativePath,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDifferent
                                      ? colorScheme.primary
                                      : null,
                                  decoration: isDifferent
                                      ? TextDecoration.underline
                                      : null,
                                  decorationColor: isDifferent
                                      ? colorScheme.primary.withValues(
                                          alpha: 0.5,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              _formatSize(entry.sizeA),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              _formatSize(entry.sizeB),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Text(
                              _formatDate(entry.lastModifiedA),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Text(
                              _formatDate(entry.lastModifiedB),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? effectiveColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? effectiveColor.withValues(alpha: 0.4)
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? effectiveColor : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
