import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/compare_result.dart';
import '../services/compare_engine.dart';

/// Full-screen modal dialog for diff comparison, styled like a code editor.
class DiffDialog extends StatefulWidget {
  final String relativePath;
  final String folderAPath;
  final String folderBPath;

  const DiffDialog({
    super.key,
    required this.relativePath,
    required this.folderAPath,
    required this.folderBPath,
  });

  static Future<void> show(
    BuildContext context, {
    required String relativePath,
    required String folderAPath,
    required String folderBPath,
  }) {
    return showDialog(
      context: context,
      builder: (_) => DiffDialog(
        relativePath: relativePath,
        folderAPath: folderAPath,
        folderBPath: folderBPath,
      ),
    );
  }

  @override
  State<DiffDialog> createState() => _DiffDialogState();
}

class _DiffDialogState extends State<DiffDialog> {
  DiffResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiff();
  }

  Future<void> _loadDiff() async {
    try {
      final result = await CompareEngine.diffFiles(
        widget.folderAPath,
        widget.folderBPath,
        widget.relativePath,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = DiffResult(
            relativePath: widget.relativePath,
            lines: [],
            error: e.toString(),
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: size.width * 0.85,
        height: size.height * 0.85,
        color: colorScheme.surface,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.difference_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.relativePath,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (_result != null && !_isLoading)
                          _buildStats(colorScheme),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Legend
                  _LegendDot(color: const Color(0xFF4CAF50), label: 'Added'),
                  const SizedBox(width: 12),
                  _LegendDot(color: const Color(0xFFEF5350), label: 'Removed'),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Body
            Expanded(child: _buildBody(colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(ColorScheme colorScheme) {
    if (_result == null || _result!.lines.isEmpty) {
      return const SizedBox.shrink();
    }
    final added = _result!.lines
        .where((l) => l.type == DiffLineType.added)
        .length;
    final removed = _result!.lines
        .where((l) => l.type == DiffLineType.removed)
        .length;
    return Text(
      '+$added added  -$removed removed',
      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_result == null) return const SizedBox.shrink();

    if (_result!.isBinary) {
      return _WarningCenter(
        icon: Icons.warning_amber_rounded,
        message: 'This is a binary file. Diff comparison is not available.',
      );
    }
    if (_result!.isTooLarge) {
      return _WarningCenter(
        icon: Icons.warning_amber_rounded,
        message: 'File exceeds 2MB limit. Diff comparison is not available.',
      );
    }
    if (_result!.error != null) {
      return _WarningCenter(
        icon: Icons.error_outline_rounded,
        message: _result!.error!,
      );
    }
    if (_result!.lines.isEmpty) {
      return _WarningCenter(
        icon: Icons.check_circle_outline,
        message: 'No differences found.',
      );
    }

    return Scrollbar(
      child: ListView.builder(
        itemCount: _result!.lines.length,
        itemExtent: 22,
        itemBuilder: (context, index) {
          return _DiffLineRow(line: _result!.lines[index]);
        },
      ),
    );
  }
}

class _DiffLineRow extends StatelessWidget {
  final DiffLine line;

  const _DiffLineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    Color? bgColor;
    Color lineNumColor;
    String prefix;

    switch (line.type) {
      case DiffLineType.added:
        bgColor = isDark
            ? const Color(0xFF1B5E20).withValues(alpha: 0.3)
            : const Color(0xFFE8F5E9);
        lineNumColor = const Color(0xFF4CAF50);
        prefix = '+';
        break;
      case DiffLineType.removed:
        bgColor = isDark
            ? const Color(0xFFB71C1C).withValues(alpha: 0.2)
            : const Color(0xFFFFEBEE);
        lineNumColor = const Color(0xFFEF5350);
        prefix = '-';
        break;
      case DiffLineType.unchanged:
        bgColor = null;
        lineNumColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
        prefix = ' ';
        break;
    }

    final monoStyle = GoogleFonts.jetBrainsMono(fontSize: 12, height: 1.6);

    return Container(
      color: bgColor,
      child: Row(
        children: [
          // Old line number
          Container(
            width: 52,
            padding: const EdgeInsets.only(right: 8),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Text(
              line.lineNumberOld?.toString() ?? '',
              style: monoStyle.copyWith(fontSize: 11, color: lineNumColor),
            ),
          ),
          // New line number
          Container(
            width: 52,
            padding: const EdgeInsets.only(right: 8),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Text(
              line.lineNumberNew?.toString() ?? '',
              style: monoStyle.copyWith(fontSize: 11, color: lineNumColor),
            ),
          ),
          // Prefix
          SizedBox(
            width: 22,
            child: Text(
              prefix,
              style: monoStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: lineNumColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Content
          Expanded(
            child: Text(
              line.content,
              style: monoStyle.copyWith(color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _WarningCenter extends StatelessWidget {
  final IconData icon;
  final String message;

  const _WarningCenter({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.amber[700]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
