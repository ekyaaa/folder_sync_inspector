import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compare_result.dart';
import '../services/compare_engine.dart';

/// State for folder comparison.
class FolderCompareState {
  final String? folderAPath;
  final String? folderBPath;
  final bool isScanning;
  final CompareResult? result;
  final String? error;
  final FileStatus? filterStatus;
  final String searchQuery;
  final int progressCurrent;
  final int progressTotal;

  const FolderCompareState({
    this.folderAPath,
    this.folderBPath,
    this.isScanning = false,
    this.result,
    this.error,
    this.filterStatus,
    this.searchQuery = '',
    this.progressCurrent = 0,
    this.progressTotal = 0,
  });

  FolderCompareState copyWith({
    String? folderAPath,
    String? folderBPath,
    bool? isScanning,
    CompareResult? result,
    String? error,
    FileStatus? filterStatus,
    String? searchQuery,
    int? progressCurrent,
    int? progressTotal,
    bool clearResult = false,
    bool clearError = false,
    bool clearFilter = false,
  }) {
    return FolderCompareState(
      folderAPath: folderAPath ?? this.folderAPath,
      folderBPath: folderBPath ?? this.folderBPath,
      isScanning: isScanning ?? this.isScanning,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressTotal: progressTotal ?? this.progressTotal,
    );
  }

  /// Get filtered entries based on current filter and search.
  List<FileCompareEntry> get filteredEntries {
    if (result == null) return [];
    var entries = result!.entries;
    if (filterStatus != null) {
      entries = entries.where((e) => e.status == filterStatus).toList();
    }
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      entries = entries
          .where((e) => e.relativePath.toLowerCase().contains(query))
          .toList();
    }
    return entries;
  }
}

class FolderCompareNotifier extends StateNotifier<FolderCompareState> {
  FolderCompareNotifier() : super(const FolderCompareState());

  void setFolderA(String path) {
    state = state.copyWith(
      folderAPath: path,
      clearResult: true,
      clearError: true,
    );
  }

  void setFolderB(String path) {
    state = state.copyWith(
      folderBPath: path,
      clearResult: true,
      clearError: true,
    );
  }

  Future<void> scan() async {
    if (state.folderAPath == null || state.folderBPath == null) return;

    state = state.copyWith(
      isScanning: true,
      clearError: true,
      clearResult: true,
      progressCurrent: 0,
      progressTotal: 0,
    );

    try {
      final result = await CompareEngine.compare(
        state.folderAPath!,
        state.folderBPath!,
        onProgress: (current, total) {
          state = state.copyWith(
            progressCurrent: current,
            progressTotal: total,
          );
        },
      );
      state = state.copyWith(result: result, isScanning: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isScanning: false);
    }
  }

  void setFilter(FileStatus? status) {
    state = state.copyWith(filterStatus: status, clearFilter: status == null);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final folderCompareProvider =
    StateNotifierProvider<FolderCompareNotifier, FolderCompareState>(
      (ref) => FolderCompareNotifier(),
    );
