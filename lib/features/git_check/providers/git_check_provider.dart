import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/git_models.dart';
import '../services/git_service.dart';

/// State for git check.
/// The repo path is always Folder B from the Folder Compare section.
class GitCheckState {
  final String? folderAPath;
  final String? folderBPath; // This IS the git repo
  final List<GitCommit> commits;
  final Set<String> selectedCommitHashes;
  final bool isLoadingCommits;
  final bool isValidating;
  final GitCheckResult? result;
  final String? error;

  const GitCheckState({
    this.folderAPath,
    this.folderBPath,
    this.commits = const [],
    this.selectedCommitHashes = const {},
    this.isLoadingCommits = false,
    this.isValidating = false,
    this.result,
    this.error,
  });

  GitCheckState copyWith({
    String? folderAPath,
    String? folderBPath,
    List<GitCommit>? commits,
    Set<String>? selectedCommitHashes,
    bool? isLoadingCommits,
    bool? isValidating,
    GitCheckResult? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
    bool clearFolderA = false,
    bool clearFolderB = false,
  }) {
    return GitCheckState(
      folderAPath: clearFolderA ? null : (folderAPath ?? this.folderAPath),
      folderBPath: clearFolderB ? null : (folderBPath ?? this.folderBPath),
      commits: commits ?? this.commits,
      selectedCommitHashes: selectedCommitHashes ?? this.selectedCommitHashes,
      isLoadingCommits: isLoadingCommits ?? this.isLoadingCommits,
      isValidating: isValidating ?? this.isValidating,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GitCheckNotifier extends StateNotifier<GitCheckState> {
  GitCheckNotifier() : super(const GitCheckState());

  void setFolderAPath(String? path) {
    state = state.copyWith(
      folderAPath: path,
      clearFolderA: path == null,
      clearResult: true,
    );
  }

  /// Called when Folder B changes. Auto-loads commits from Folder B's git repo.
  Future<void> setFolderBPath(String? path) async {
    if (path == null) {
      state = state.copyWith(
        clearFolderB: true,
        clearResult: true,
        clearError: true,
        commits: [],
        selectedCommitHashes: {},
      );
      return;
    }

    state = state.copyWith(
      folderBPath: path,
      isLoadingCommits: true,
      clearError: true,
      clearResult: true,
      commits: [],
      selectedCommitHashes: {},
    );

    try {
      final commits = await GitService.loadCommits(path);
      state = state.copyWith(commits: commits, isLoadingCommits: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoadingCommits: false);
    }
  }

  void toggleCommit(String hash) {
    final selected = Set<String>.from(state.selectedCommitHashes);
    if (selected.contains(hash)) {
      selected.remove(hash);
    } else {
      selected.add(hash);
    }
    state = state.copyWith(selectedCommitHashes: selected, clearResult: true);
  }

  void selectAllCommits() {
    state = state.copyWith(
      selectedCommitHashes: state.commits.map((c) => c.hash).toSet(),
      clearResult: true,
    );
  }

  void deselectAllCommits() {
    state = state.copyWith(selectedCommitHashes: {}, clearResult: true);
  }

  Future<void> validate() async {
    if (state.folderBPath == null || state.folderAPath == null) return;
    if (state.selectedCommitHashes.isEmpty) return;

    state = state.copyWith(isValidating: true, clearError: true);

    try {
      final result = await GitService.validateAgainstFolderA(
        state.folderBPath!,
        state.selectedCommitHashes.toList(),
        state.folderAPath!,
      );
      state = state.copyWith(result: result, isValidating: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isValidating: false);
    }
  }
}

final gitCheckProvider = StateNotifierProvider<GitCheckNotifier, GitCheckState>(
  (ref) => GitCheckNotifier(),
);
