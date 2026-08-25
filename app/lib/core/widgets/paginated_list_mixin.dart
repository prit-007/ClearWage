import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

const int kDefaultPageSize = 20;

/// Callback that fetches a page of items.
/// [offset] is the number of items to skip (0 for first page).
/// [limit] is the page size.
/// Should return the list of items fetched.
typedef FetchPage<T> = Future<List<T>> Function(int offset, int limit);

/// A reusable helper that manages paginated list state: loading, scroll
/// detection, refresh, and load-more logic.
///
/// Compose this into your State class and call [init], [dispose], [onRefresh].
///
/// Example:
/// ```dart
/// class _MyScreenState extends ConsumerState<MyScreen> {
///   late final _pagination = PaginatedList<Employee>(
///     setState: setState,
///     mounted: () => mounted,
///     fetchPage: (offset, limit) =>
///         ref.read(staffServiceProvider).list(offset: offset, limit: limit),
///   );
///
///   @override
///   void initState() {
///     super.initState();
///     _pagination.init();
///   }
///
///   @override
///   void dispose() {
///     _pagination.dispose();
///     super.dispose();
///   }
/// }
/// ```
class PaginatedList<T> {
  final ScrollController scrollCtrl = ScrollController();
  final void Function(VoidCallback) setState;
  final bool Function() mounted;
  final FetchPage<T> fetchPage;
  final int pageSize;

  List<T> items = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  String? paginationError;
  int _page = 0;

  PaginatedList({
    required this.setState,
    required this.mounted,
    required this.fetchPage,
    this.pageSize = kDefaultPageSize,
  });

  void init() {
    scrollCtrl.addListener(_onScroll);
    _fetchInitial();
  }

  void dispose() {
    scrollCtrl.removeListener(_onScroll);
    scrollCtrl.dispose();
  }

  void _onScroll() {
    if (scrollCtrl.position.pixels >=
            scrollCtrl.position.maxScrollExtent - 200 &&
        !loadingMore &&
        !loading &&
        hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
    }
  }

  Future<void> _fetchInitial() async {
    setState(() {
      loading = true;
      paginationError = null;
      items = [];
      _page = 0;
      hasMore = true;
    });
    try {
      final result = await fetchPage(0, pageSize);
      if (mounted()) {
        setState(() {
          items = result;
          _page = 1;
          hasMore = result.length >= pageSize;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted()) {
        setState(() {
          paginationError = e.toString();
          loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (loadingMore || !hasMore) return;
    unawaited(HapticFeedback.lightImpact());
    setState(() => loadingMore = true);
    try {
      final result = await fetchPage(_page * pageSize, pageSize);
      if (mounted()) {
        setState(() {
          items.addAll(result);
          _page++;
          hasMore = result.length >= pageSize;
          loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted()) setState(() => loadingMore = false);
    }
  }

  Future<void> onRefresh() async {
    unawaited(HapticFeedback.mediumImpact());
    await _fetchInitial();
  }

  /// Returns a widget to show at the bottom of the list for load-more feedback.
  Widget buildLoadMoreIndicator() {
    if (!loadingMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
