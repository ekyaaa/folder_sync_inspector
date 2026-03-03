import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/git_models.dart';

/// Multi-select commit list for git check.
class CommitList extends StatelessWidget {
  final List<GitCommit> commits;
  final Set<String> selectedHashes;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  const CommitList({
    super.key,
    required this.commits,
    required this.selectedHashes,
    required this.onToggle,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  static String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final commitDay = DateTime(dt.year, dt.month, dt.day);
    final dayDiff = today.difference(commitDay).inDays;
    final date =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (dayDiff == 0) return 'Today $time';
    if (dayDiff == 1) return 'Yesterday $time';
    return '$date $time';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with select/deselect actions
        Row(
          children: [
            Text(
              '${commits.length} commits',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (selectedHashes.length < commits.length)
              TextButton.icon(
                onPressed: onSelectAll,
                icon: const Icon(Icons.select_all_rounded, size: 16),
                label: const Text('Select All'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            if (selectedHashes.isNotEmpty)
              TextButton.icon(
                onPressed: onDeselectAll,
                icon: const Icon(Icons.deselect_rounded, size: 16),
                label: const Text('Deselect'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Commit list
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: commits.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
              itemBuilder: (context, index) {
                final commit = commits[index];
                final isSelected = selectedHashes.contains(commit.hash);

                return InkWell(
                  onTap: () => onToggle(commit.hash),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    color: isSelected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : null,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (_) => onToggle(commit.hash),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            commit.hash,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            commit.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (commit.dateTime != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            _formatDateTime(commit.dateTime!),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        if (selectedHashes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${selectedHashes.length} commit${selectedHashes.length > 1 ? 's' : ''} selected',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
