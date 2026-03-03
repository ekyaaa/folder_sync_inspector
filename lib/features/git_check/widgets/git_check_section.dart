import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/git_check_provider.dart';
import '../../folder_compare/providers/folder_compare_provider.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/empty_state.dart';
import 'commit_list.dart';
import 'git_results_table.dart';

/// Main section card for git check.
/// Automatically uses Folder B (Project) as the git repository.
class GitCheckSection extends ConsumerWidget {
  const GitCheckSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gitCheckProvider);
    final notifier = ref.read(gitCheckProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    // Watch both folders from folder compare
    final folderAPath = ref.watch(folderCompareProvider).folderAPath;
    final folderBPath = ref.watch(folderCompareProvider).folderBPath;

    // Sync Folder A path
    ref.listen<String?>(folderCompareProvider.select((s) => s.folderAPath), (
      prev,
      next,
    ) {
      notifier.setFolderAPath(next);
    });

    // Sync Folder B path → auto-load commits
    ref.listen<String?>(folderCompareProvider.select((s) => s.folderBPath), (
      prev,
      next,
    ) {
      notifier.setFolderBPath(next);
    });

    final hasBothFolders = folderAPath != null && folderBPath != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              icon: Icons.commit_rounded,
              title: 'Git Check',
              subtitle:
                  'Validate git commit changes from Folder B against Folder A',
            ),
            const SizedBox(height: 20),

            // Folder reference display
            Row(
              children: [
                Expanded(
                  child: _FolderRefCard(
                    label: 'FOLDER A (Changes)',
                    icon: Icons.folder_special_outlined,
                    path: folderAPath,
                    emptyHint: 'Select in Folder Compare above',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FolderRefCard(
                    label: 'FOLDER B (Git Repository)',
                    icon: Icons.source_outlined,
                    path: folderBPath,
                    emptyHint: 'Select in Folder Compare above',
                    showGitBadge:
                        folderBPath != null && state.commits.isNotEmpty,
                  ),
                ),
              ],
            ),

            // Loading commits
            if (state.isLoadingCommits) ...[
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Loading commits from Folder B…'),
                  ],
                ),
              ),
            ],

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

            // Commits list
            if (state.commits.isNotEmpty) ...[
              const SizedBox(height: 20),
              CommitList(
                commits: state.commits,
                selectedHashes: state.selectedCommitHashes,
                onToggle: notifier.toggleCommit,
                onSelectAll: notifier.selectAllCommits,
                onDeselectAll: notifier.deselectAllCommits,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed:
                        state.isValidating ||
                            state.selectedCommitHashes.isEmpty ||
                            folderAPath == null
                        ? null
                        : () => notifier.validate(),
                    icon: state.isValidating
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.fact_check_outlined, size: 18),
                    label: Text(
                      state.isValidating
                          ? 'Validating…'
                          : 'Validate Against Folder A',
                    ),
                  ),
                  if (state.selectedCommitHashes.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${state.selectedCommitHashes.length} commit${state.selectedCommitHashes.length > 1 ? 's' : ''} selected',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (folderAPath == null && state.selectedCommitHashes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Select Folder A in the Folder Compare section above first.',
                    style: TextStyle(fontSize: 12, color: Colors.amber[700]),
                  ),
                ),
            ],

            // Results
            if (state.result != null) ...[
              const SizedBox(height: 24),
              GitResultsTable(result: state.result!),
            ] else if (!state.isLoadingCommits && !hasBothFolders)
              const EmptyState(
                icon: Icons.commit_rounded,
                title: 'Select folders above to get started',
                subtitle:
                    'Pick Folder A (changes) and Folder B (project) in the Folder Compare section.\n'
                    'Git commits will be loaded automatically from Folder B.',
              ),
          ],
        ),
      ),
    );
  }
}

/// Read-only folder reference card showing linked folder path.
class _FolderRefCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? path;
  final String emptyHint;
  final bool showGitBadge;

  const _FolderRefCard({
    required this.label,
    required this.icon,
    this.path,
    required this.emptyHint,
    this.showGitBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPath = path != null;

    return Container(
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
            color: hasPath ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
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
                    if (showGitBadge) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'GIT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasPath ? path! : emptyHint,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasPath
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
