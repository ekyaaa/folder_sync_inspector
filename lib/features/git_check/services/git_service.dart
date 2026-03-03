import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/git_models.dart';
import '../../../app/constants.dart';

/// Service for interacting with local git repositories via Process.run.
class GitService {
  /// Load the latest commits from a git repository.
  static Future<List<GitCommit>> loadCommits(String repoPath) async {
    await _validateGitRepo(repoPath);

    final result = await Process.run('git', [
      'log',
      '--format=%h||%aI||%s',
      '-n',
      '${AppConstants.gitLogLimit}',
    ], workingDirectory: repoPath);

    if (result.exitCode != 0) {
      throw Exception('Failed to load git log: ${result.stderr}');
    }

    final output = (result.stdout as String).trim();
    if (output.isEmpty) return [];

    final commits = <GitCommit>[];
    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final parts = trimmed.split('||');
      if (parts.length >= 3) {
        DateTime? dateTime;
        try {
          dateTime = DateTime.parse(parts[1]).toLocal();
        } catch (_) {}
        commits.add(
          GitCommit(
            hash: parts[0],
            message: parts.sublist(2).join('||'),
            dateTime: dateTime,
          ),
        );
      } else {
        commits.add(GitCommit(hash: trimmed, message: ''));
      }
    }
    return commits;
  }

  /// Get changed files from the selected commits.
  static Future<List<String>> getChangedFiles(
    String repoPath,
    List<String> commitHashes,
  ) async {
    final uniqueFiles = <String>{};

    for (final hash in commitHashes) {
      final result = await Process.run('git', [
        'show',
        '--name-only',
        '--pretty=format:',
        hash,
      ], workingDirectory: repoPath);

      if (result.exitCode != 0) continue;

      final output = (result.stdout as String).trim();
      for (final line in output.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          uniqueFiles.add(trimmed);
        }
      }
    }

    final sorted = uniqueFiles.toList()..sort();
    return sorted;
  }

  /// Validate changed files against Folder A.
  static Future<GitCheckResult> validateAgainstFolderA(
    String repoPath,
    List<String> commitHashes,
    String folderAPath,
  ) async {
    final changedFiles = await getChangedFiles(repoPath, commitHashes);

    final entries = <GitFileEntry>[];
    int presentCount = 0;
    int missingCount = 0;

    for (final filePath in changedFiles) {
      final fullPath = p.join(folderAPath, filePath);
      final exists = await File(fullPath).exists();

      if (exists) {
        presentCount++;
      } else {
        missingCount++;
      }

      entries.add(GitFileEntry(path: filePath, presentInA: exists));
    }

    return GitCheckResult(
      entries: entries,
      totalChangedFiles: changedFiles.length,
      presentInA: presentCount,
      missingInA: missingCount,
    );
  }

  static Future<void> _validateGitRepo(String repoPath) async {
    final dir = Directory(repoPath);
    if (!await dir.exists()) {
      throw Exception('Directory does not exist: $repoPath');
    }

    final gitDir = Directory(p.join(repoPath, '.git'));
    if (!await gitDir.exists()) {
      throw Exception(
        'Not a git repository: $repoPath\n'
        'No .git directory found.',
      );
    }

    // Verify git is available
    try {
      final result = await Process.run('git', [
        '--version',
      ], workingDirectory: repoPath);
      if (result.exitCode != 0) {
        throw Exception('Git is not available on this system.');
      }
    } catch (e) {
      throw Exception(
        'Git is not installed or not in PATH.\n'
        'Please install git to use this feature.',
      );
    }
  }
}
