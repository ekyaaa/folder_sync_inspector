import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:path/path.dart' as p;
import '../models/compare_result.dart';
import '../../../app/constants.dart';

/// Engine for comparing folder contents using SHA-256 hashing and line-based diff.
class CompareEngine {
  /// Compare all files in [folderAPath] against [folderBPath].
  /// Files in B that don't exist in A are ignored.
  static Future<CompareResult> compare(
    String folderAPath,
    String folderBPath, {
    void Function(int current, int total)? onProgress,
  }) async {
    final dirA = Directory(folderAPath);
    if (!await dirA.exists()) {
      throw Exception('Folder A does not exist: $folderAPath');
    }

    // Collect all files in A
    final filesA = <String>[];
    await for (final entity in dirA.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: folderAPath);
        filesA.add(relativePath);
      }
    }

    if (filesA.isEmpty) {
      return const CompareResult(
        entries: [],
        totalFiles: 0,
        matchCount: 0,
        differentCount: 0,
        missingCount: 0,
      );
    }

    filesA.sort();
    final entries = <FileCompareEntry>[];
    int matchCount = 0;
    int differentCount = 0;
    int missingCount = 0;

    for (int i = 0; i < filesA.length; i++) {
      final relPath = filesA[i];
      final fileA = File(p.join(folderAPath, relPath));
      final fileB = File(p.join(folderBPath, relPath));

      onProgress?.call(i + 1, filesA.length);

      final statA = await fileA.stat();

      if (!await fileB.exists()) {
        missingCount++;
        entries.add(
          FileCompareEntry(
            relativePath: relPath,
            status: FileStatus.missing,
            sizeA: statA.size,
            sizeB: null,
            lastModifiedA: statA.modified,
            lastModifiedB: null,
          ),
        );
        continue;
      }

      final statB = await fileB.stat();

      // Compare using SHA-256
      final hashA = await _hashFile(fileA);
      final hashB = await _hashFile(fileB);

      if (hashA == hashB) {
        matchCount++;
        entries.add(
          FileCompareEntry(
            relativePath: relPath,
            status: FileStatus.match,
            sizeA: statA.size,
            sizeB: statB.size,
            lastModifiedA: statA.modified,
            lastModifiedB: statB.modified,
          ),
        );
      } else {
        differentCount++;
        entries.add(
          FileCompareEntry(
            relativePath: relPath,
            status: FileStatus.different,
            sizeA: statA.size,
            sizeB: statB.size,
            lastModifiedA: statA.modified,
            lastModifiedB: statB.modified,
          ),
        );
      }
    }

    return CompareResult(
      entries: entries,
      totalFiles: filesA.length,
      matchCount: matchCount,
      differentCount: differentCount,
      missingCount: missingCount,
    );
  }

  /// Generate a line-based diff between two files.
  static Future<DiffResult> diffFiles(
    String folderAPath,
    String folderBPath,
    String relativePath,
  ) async {
    final fileA = File(p.join(folderAPath, relativePath));
    final fileB = File(p.join(folderBPath, relativePath));

    if (!await fileA.exists() || !await fileB.exists()) {
      return DiffResult(
        relativePath: relativePath,
        lines: [],
        error: 'One or both files do not exist.',
      );
    }

    final sizeA = await fileA.length();
    final sizeB = await fileB.length();

    if (sizeA > AppConstants.maxDiffFileSizeBytes ||
        sizeB > AppConstants.maxDiffFileSizeBytes) {
      return DiffResult(
        relativePath: relativePath,
        lines: [],
        isTooLarge: true,
      );
    }

    // Check if binary
    if (_isBinaryPath(relativePath)) {
      return DiffResult(relativePath: relativePath, lines: [], isBinary: true);
    }

    try {
      final contentA = await fileA.readAsString();
      final contentB = await fileB.readAsString();
      final diffLines = _computeLineDiff(contentA, contentB);

      return DiffResult(relativePath: relativePath, lines: diffLines);
    } catch (e) {
      // Likely a binary file that can't be read as string
      return DiffResult(relativePath: relativePath, lines: [], isBinary: true);
    }
  }

  static Future<String> _hashFile(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  static bool _isBinaryPath(String path) {
    final binaryExtensions = {
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.bmp',
      '.ico',
      '.webp',
      '.mp3',
      '.mp4',
      '.wav',
      '.avi',
      '.mov',
      '.mkv',
      '.zip',
      '.tar',
      '.gz',
      '.rar',
      '.7z',
      '.exe',
      '.dll',
      '.so',
      '.dylib',
      '.o',
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ttf',
      '.otf',
      '.woff',
      '.woff2',
      '.class',
      '.jar',
      '.pyc',
    };
    final ext = p.extension(path).toLowerCase();
    return binaryExtensions.contains(ext);
  }

  static List<DiffLine> _computeLineDiff(String textA, String textB) {
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(textA, textB);
    dmp.diffCleanupSemantic(diffs);

    // Convert diff patches to line-based diff
    final lines = <DiffLine>[];
    int lineOld = 1;
    int lineNew = 1;

    for (final diff in diffs) {
      final diffLines = const LineSplitter().convert(diff.text);

      for (int i = 0; i < diffLines.length; i++) {
        final content = diffLines[i];
        final isLastSegment =
            i == diffLines.length - 1 && !diff.text.endsWith('\n');

        switch (diff.operation) {
          case DIFF_EQUAL:
            lines.add(
              DiffLine(
                lineNumberOld: lineOld,
                lineNumberNew: lineNew,
                content: content,
                type: DiffLineType.unchanged,
              ),
            );
            if (!isLastSegment || diff.text.endsWith('\n')) {
              lineOld++;
              lineNew++;
            }
            break;
          case DIFF_DELETE:
            lines.add(
              DiffLine(
                lineNumberOld: lineOld,
                lineNumberNew: null,
                content: content,
                type: DiffLineType.removed,
              ),
            );
            if (!isLastSegment || diff.text.endsWith('\n')) {
              lineOld++;
            }
            break;
          case DIFF_INSERT:
            lines.add(
              DiffLine(
                lineNumberOld: null,
                lineNumberNew: lineNew,
                content: content,
                type: DiffLineType.added,
              ),
            );
            if (!isLastSegment || diff.text.endsWith('\n')) {
              lineNew++;
            }
            break;
        }
      }
    }

    return lines;
  }
}
