import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/category/category_repository.dart';
import 'package:app/data/repositories/request/request_repository.dart';
import 'package:app/domain/models/request_category.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/domain/models/request_sort.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';

/// Drives the requests list: filters, search, paging and refresh.
///
/// It holds all of the screen's state and none of its widgets, which is what
/// makes it testable in a plain Dart unit test.
class RequestListViewModel extends ChangeNotifier {
  RequestListViewModel({
    required this._requestRepository,
    required this._categoryRepository,
  }) {
    load = Command0(_load)..execute();
    loadMore = Command0(_loadMore);
    loadCategories = Command0(_loadCategories)..execute();
  }

  final RequestRepository _requestRepository;
  final CategoryRepository _categoryRepository;

  /// Typing shouldn't fire a request per keystroke.
  static const _searchDebounce = Duration(milliseconds: 350);
  static const _pageSize = 20;

  /// Loads the first page. Also the retry target for the error state.
  late final Command0<void> load;

  /// Appends the next page.
  late final Command0<void> loadMore;

  /// Fills the filter sheet's category dropdown.
  late final Command0<void> loadCategories;

  RequestFilters _filters = const RequestFilters(limit: _pageSize);
  List<Request> _items = const [];
  List<RequestCategory> _categoryOptions = const [];
  int _total = 0;
  bool _hasMore = false;
  Timer? _debounce;
  bool _reloadQueued = false;

  RequestFilters get filters => _filters;
  UnmodifiableListView<Request> get items => UnmodifiableListView(_items);
  UnmodifiableListView<RequestCategory> get categoryOptions =>
      UnmodifiableListView(_categoryOptions);
  int get total => _total;
  bool get hasMore => _hasMore;
  bool get isEmpty => _items.isEmpty;
  bool get isFiltering => _filters.isFiltering;

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      _filters = query.trim().isEmpty
          ? _filters.copyWith(clearQuery: true, offset: 0)
          : _filters.copyWith(query: query, offset: 0);
      _refresh();
    });
  }

  void applyFilters(RequestFilters filters) {
    _filters = filters.copyWith(offset: 0, limit: _pageSize);
    _refresh();
  }

  void clearFilters() {
    _filters = const RequestFilters(limit: _pageSize);
    _refresh();
  }

  void setSort(RequestSort sort) {
    _filters = _filters.copyWith(sort: sort, offset: 0);
    _refresh();
  }

  /// Swaps one row in place after the detail screen changed it, so returning to
  /// the list does not require a full reload.
  void replace(Request updated) {
    final index = _items.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;

    // A status change can push a row out of the current filter; drop it rather
    // than show something the filter says should not be there.
    final stillMatches =
        _filters.status == null || _filters.status == updated.status;
    _items = [..._items]
      ..replaceRange(index, index + 1, [if (stillMatches) updated]);
    notifyListeners();
  }

  /// A [Command] deliberately ignores `execute()` while it is already running,
  /// which would silently drop a filter change made mid-load. Queueing one
  /// re-run keeps the list consistent with the newest filters.
  Future<void> _refresh() async {
    if (load.running) {
      _reloadQueued = true;
      return;
    }

    await load.execute();

    if (_reloadQueued) {
      _reloadQueued = false;
      await _refresh();
    }
  }

  Future<Result<void>> _load() async {
    final result = await _requestRepository.getRequests(
      _filters.copyWith(offset: 0),
    );

    switch (result) {
      case Ok<RequestPage>(:final value):
        _items = value.items;
        _total = value.total;
        _hasMore = value.hasMore;
        notifyListeners();
        return const Result.ok(null);
      case Error<RequestPage>(:final error):
        _items = const [];
        _total = 0;
        _hasMore = false;
        notifyListeners();
        return Result.error(error);
    }
  }

  Future<Result<void>> _loadMore() async {
    if (!_hasMore || load.running) return const Result.ok(null);

    final result = await _requestRepository.getRequests(
      _filters.copyWith(offset: _items.length),
    );

    switch (result) {
      case Ok<RequestPage>(:final value):
        _items = [..._items, ...value.items];
        _total = value.total;
        _hasMore = value.hasMore;
        notifyListeners();
        return const Result.ok(null);
      case Error<RequestPage>(:final error):
        return Result.error(error);
    }
  }

  /// A failure here is not worth failing the screen over — the filter sheet
  /// simply offers no categories.
  Future<Result<void>> _loadCategories() async {
    final result = await _categoryRepository.getCategories();
    if (result is Ok<List<RequestCategory>>) {
      _categoryOptions = result.value;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    load.dispose();
    loadMore.dispose();
    loadCategories.dispose();
    super.dispose();
  }
}
