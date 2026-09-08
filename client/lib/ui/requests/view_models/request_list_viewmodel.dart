import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/category/category_repository.dart';
import 'package:app/data/repositories/request/request_repository.dart';
import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/domain/models/request_category.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/domain/models/request_sort.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/debounced_refresh.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/safe_notifier.dart';

class RequestListViewModel extends ChangeNotifier with SafeNotifier {
  RequestListViewModel({
    required this._requestRepository,
    required this._categoryRepository,
    required this._sessionRepository,
  }) {
    load = Command0(_load)..execute();
    loadMore = Command0(_loadMore);
    loadCategories = Command0(_loadCategories)..execute();
    _refresh = DebouncedRefresh(load);
  }

  final RequestRepository _requestRepository;
  final CategoryRepository _categoryRepository;
  final SessionRepository _sessionRepository;

  static const _pageSize = 20;

  late final Command0<void> load;

  late final Command0<void> loadMore;

  late final Command0<void> loadCategories;

  late final DebouncedRefresh _refresh;

  RequestFilters _filters = const RequestFilters(limit: _pageSize);
  List<Request> _items = const [];
  List<RequestCategory> _categoryOptions = const [];
  int _total = 0;
  bool _hasMore = false;

  /// Who is filtering, which the filter sheet needs to offer "assigned to me".
  ///
  /// Exposed here so the screen reads its view model rather than reaching into
  /// the repository layer for one field.
  User? get currentUser => _sessionRepository.currentUser;

  RequestFilters get filters => _filters;
  UnmodifiableListView<Request> get items => UnmodifiableListView(_items);
  UnmodifiableListView<RequestCategory> get categoryOptions =>
      UnmodifiableListView(_categoryOptions);
  int get total => _total;
  bool get hasMore => _hasMore;
  bool get isEmpty => _items.isEmpty;
  bool get isFiltering => _filters.isFiltering;

  void search(String query) => _refresh.schedule(() {
    _filters = query.trim().isEmpty
        ? _filters.copyWith(clearQuery: true, offset: 0)
        : _filters.copyWith(query: query, offset: 0);
  });

  void applyFilters(RequestFilters filters) {
    _filters = filters.copyWith(offset: 0, limit: _pageSize);
    _refresh.now();
  }

  void clearFilters() {
    _filters = const RequestFilters(limit: _pageSize);
    _refresh.now();
  }

  void setSort(RequestSort sort) {
    _filters = _filters.copyWith(sort: sort, offset: 0);
    _refresh.now();
  }

  void replace(Request updated) {
    final index = _items.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;

    final stillMatches =
        _filters.status == null || _filters.status == updated.status;
    _items = [..._items]
      ..replaceRange(index, index + 1, [if (stillMatches) updated]);
    notifyListeners();
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
    _refresh.cancel();
    load.dispose();
    loadMore.dispose();
    loadCategories.dispose();
    super.dispose();
  }
}
