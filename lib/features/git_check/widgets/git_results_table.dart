import 'package:flutter/material.dart';
import '../models/git_models.dart';
import '../../../shared/widgets/status_chip.dart';

/// DataTable for git check validation results.
class GitResultsTable extends StatelessWidget {
  final GitCheckResult result;

  const GitResultsTable({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MiniStat(
              label: 'Total Changed',
              value: '${result.totalChangedFiles}',
              color: colorScheme.primary,
            ),
            _MiniStat(
              label: 'Present in A',
              value: '${result.presentInA}',
              color: const Color(0xFF2E7D32),
            ),
            _MiniStat(
              label: 'Missing in A',
              value: '${result.missingInA}',
              color: const Color(0xFFC62828),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table
        if (result.entries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No changed files found in the selected commits.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 600),
                  child: DataTable(
                    showCheckboxColumn: false,
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    headingRowHeight: 44,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 44,
                    columns: const [
                      DataColumn(label: Text('File Path')),
                      DataColumn(label: Text('Present in A')),
                    ],
                    rows: result.entries.map((entry) {
                      return DataRow(
                        color: !entry.presentInA
                            ? WidgetStatePropertyAll(
                                const Color(0xFFC62828).withValues(alpha: 0.06),
                              )
                            : null,
                        cells: [
                          DataCell(
                            Tooltip(
                              message: entry.path,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 500,
                                ),
                                child: Text(
                                  entry.path,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          DataCell(PresenceChip(present: entry.presentInA)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
