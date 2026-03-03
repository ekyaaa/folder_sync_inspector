// Models for git check results.

class GitCommit {
  final String hash;
  final String message;
  final DateTime? dateTime;

  const GitCommit({required this.hash, required this.message, this.dateTime});
}

class GitFileEntry {
  final String path;
  final bool presentInA;

  const GitFileEntry({required this.path, required this.presentInA});
}

class GitCheckResult {
  final List<GitFileEntry> entries;
  final int totalChangedFiles;
  final int presentInA;
  final int missingInA;

  const GitCheckResult({
    required this.entries,
    required this.totalChangedFiles,
    required this.presentInA,
    required this.missingInA,
  });
}
