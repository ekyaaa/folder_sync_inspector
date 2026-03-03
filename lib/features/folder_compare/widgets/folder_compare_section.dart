import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/folder_compare_provider.dart';
import '../../../shared/widgets/folder_picker_field.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/empty_state.dart';
import 'summary_cards.dart';
import 'compare_table.dart';

/// Main section card for folder comparison.
class FolderCompareSection extends ConsumerWidget {
  const FolderCompareSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(folderCompareProvider);
    final notifier = ref.read(folderCompareProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              icon: Icons.folder_copy_outlined,
              title: 'Folder Compare',
              subtitle:
                  'Compare files in Folder A against Folder B to check sync status',
            ),
            const SizedBox(height: 20),

            // Folder pickers
            Row(
              children: [
                Expanded(
                  child: FolderPickerField(
                    label: 'FOLDER A (Changes)',
                    icon: Icons.folder_special_outlined,
                    selectedPath: state.folderAPath,
                    onSelected: notifier.setFolderA,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FolderPickerField(
                    label: 'FOLDER B (Project)',
                    icon: Icons.folder_outlined,
                    selectedPath: state.folderBPath,
                    onSelected: notifier.setFolderB,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scan button
            Row(
              children: [
                FilledButton.icon(
                  onPressed:
                      state.isScanning ||
                          state.folderAPath == null ||
                          state.folderBPath == null
                      ? null
                      : () => notifier.scan(),
                  icon: state.isScanning
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.compare_arrows_rounded, size: 18),
                  label: Text(
                    state.isScanning ? 'Scanning…' : 'Scan & Compare',
                  ),
                ),
                if (state.isScanning && state.progressTotal > 0) ...[
                  const SizedBox(width: 16),
                  Text(
                    '${state.progressCurrent} / ${state.progressTotal} files',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),

            // Error
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Results
            if (state.result != null) ...[
              const SizedBox(height: 24),
              SummaryCards(
                totalFiles: state.result!.totalFiles,
                matchCount: state.result!.matchCount,
                differentCount: state.result!.differentCount,
                missingCount: state.result!.missingCount,
                similarityPercent: state.result!.similarityPercent,
              ),
              const SizedBox(height: 24),
              CompareTable(
                entries: state.filteredEntries,
                activeFilter: state.filterStatus,
                searchQuery: state.searchQuery,
                folderAPath: state.folderAPath!,
                folderBPath: state.folderBPath!,
                onFilterChanged: notifier.setFilter,
                onSearchChanged: notifier.setSearchQuery,
              ),
            ] else if (!state.isScanning)
              const EmptyState(
                icon: Icons.folder_copy_outlined,
                title: 'Select two folders to compare',
                subtitle:
                    'Pick Folder A (changes) and Folder B (project), then click Scan to start.',
              ),
          ],
        ),
      ),
    );
  }
}
