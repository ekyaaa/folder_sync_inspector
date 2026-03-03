// Models for folder comparison results.

enum FileStatus { match, different, missing }

class FileCompareEntry {
  final String relativePath;
  final FileStatus status;
  final int? sizeA;
  final int? sizeB;
  final DateTime? lastModifiedA;
  final DateTime? lastModifiedB;

  const FileCompareEntry({
    required this.relativePath,
    required this.status,
    this.sizeA,
    this.sizeB,
    this.lastModifiedA,
    this.lastModifiedB,
  });
}

class CompareResult {
  final List<FileCompareEntry> entries;
  final int totalFiles;
  final int matchCount;
  final int differentCount;
  final int missingCount;

  const CompareResult({
    required this.entries,
    required this.totalFiles,
    required this.matchCount,
    required this.differentCount,
    required this.missingCount,
  });

  double get similarityPercent =>
      totalFiles == 0 ? 0 : (matchCount / totalFiles) * 100;
}

enum DiffLineType { unchanged, added, removed }

class DiffLine {
  final int? lineNumberOld;
  final int? lineNumberNew;
  final String content;
  final DiffLineType type;

  const DiffLine({
    this.lineNumberOld,
    this.lineNumberNew,
    required this.content,
    required this.type,
  });
}

class DiffResult {
  final String relativePath;
  final List<DiffLine> lines;
  final bool isBinary;
  final bool isTooLarge;
  final String? error;

  const DiffResult({
    required this.relativePath,
    required this.lines,
    this.isBinary = false,
    this.isTooLarge = false,
    this.error,
  });
}
