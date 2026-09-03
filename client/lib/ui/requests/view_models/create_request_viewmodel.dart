import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/category/category_repository.dart';
import 'package:app/data/repositories/request/request_repository.dart';
import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/domain/models/request_category.dart';
import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';

typedef RequestDraft = ({String title, String description});

class CreateRequestViewModel extends ChangeNotifier {
  CreateRequestViewModel({
    required this._requestRepository,
    required this._categoryRepository,
    required this._sessionRepository,
  }) {
    load = Command0(_load)..execute();
    submit = Command1(_submit);
  }

  final RequestRepository _requestRepository;
  final CategoryRepository _categoryRepository;
  final SessionRepository _sessionRepository;

  late final Command0<void> load;
  late final Command1<RequestDetail, RequestDraft> submit;

  List<RequestCategory> _categoryOptions = const [];
  RequestCategory? _selectedCategory;
  Priority _priority = Priority.medium;

  UnmodifiableListView<RequestCategory> get categoryOptions =>
      UnmodifiableListView(_categoryOptions);
  RequestCategory? get selectedCategory => _selectedCategory;
  Priority get priority => _priority;
  String? get requesterName => _sessionRepository.currentUser?.name;
  bool get canSubmit => !submit.running && _selectedCategory != null;

  void selectCategory(RequestCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void selectPriority(Priority priority) {
    _priority = priority;
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    final result = await _categoryRepository.getCategories();

    switch (result) {
      case Ok<List<RequestCategory>>(:final value):
        _categoryOptions = value;
        _selectedCategory ??= value.isEmpty ? null : value.first;
        notifyListeners();
        return const Result.ok(null);
      case Error<List<RequestCategory>>(:final error):
        return Result.error(error);
    }
  }

  Future<Result<RequestDetail>> _submit(RequestDraft draft) async {
    final category = _selectedCategory;

    if (category == null) {
      return Result.error(StateError('No category selected').toException());
    }

    return _requestRepository.createRequest(
      NewRequest(
        title: draft.title.trim(),
        description: draft.description.trim(),
        categoryId: category.id,
        priority: _priority,
      ),
    );
  }

  @override
  void dispose() {
    load.dispose();
    submit.dispose();
    super.dispose();
  }
}

extension on StateError {
  Exception toException() => Exception(message);
}
