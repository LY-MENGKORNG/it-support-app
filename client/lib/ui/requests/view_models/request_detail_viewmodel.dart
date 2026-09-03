import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/category/category_repository.dart';
import 'package:app/data/repositories/request/request_repository.dart';
import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/domain/models/request_category.dart';
import 'package:app/domain/models/comment.dart';
import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_status.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';

class RequestDetailViewModel extends ChangeNotifier {
  RequestDetailViewModel({
    required this._requestRepository,
    required this._userRepository,
    required this._categoryRepository,
    required this._sessionRepository,
    required this.requestId,
    Request? preview,
  }) : _detail = preview == null
           ? null
           : RequestDetail(
               request: preview,
               comments: const [],
               history: const [],
             ) {
    load = Command0(_load)..execute();
    changeStatus = Command1(_changeStatus);
    changePriority = Command1(_changePriority);
    assign = Command1(_assign);
    addComment = Command1(_addComment);

    if (_sessionRepository.canManageRequests) {
      loadActionOptions = Command0(_loadActionOptions)..execute();
    } else {
      loadActionOptions = Command0(_loadActionOptions);
    }
  }

  final RequestRepository _requestRepository;
  final UserRepository _userRepository;
  final CategoryRepository _categoryRepository;
  final SessionRepository _sessionRepository;
  final int requestId;

  late final Command0<void> load;
  late final Command0<void> loadActionOptions;
  late final Command1<void, RequestStatus> changeStatus;
  late final Command1<void, Priority> changePriority;

  /// `null` unassigns.
  late final Command1<void, int?> assign;
  late final Command1<void, String> addComment;

  RequestDetail? _detail;
  List<User> _assignableUsers = const [];
  List<RequestCategory> _categoryOptions = const [];

  RequestDetail? get detail => _detail;
  Request? get request => _detail?.request;
  UnmodifiableListView<User> get assignableUsers =>
      UnmodifiableListView(_assignableUsers);
  UnmodifiableListView<RequestCategory> get categoryOptions =>
      UnmodifiableListView(_categoryOptions);

  bool get canManage => _sessionRepository.canManageRequests;

  bool get isPreviewOnly => _detail != null && load.running;

  bool get isMutating =>
      changeStatus.running ||
      changePriority.running ||
      assign.running ||
      addComment.running;

  Listenable get mutations =>
      Listenable.merge([changeStatus, changePriority, assign, addComment]);

  Future<Result<void>> _load() async {
    final result = await _requestRepository.getRequest(requestId);

    switch (result) {
      case Ok<RequestDetail>(:final value):
        _detail = value;
        notifyListeners();
        return const Result.ok(null);
      case Error<RequestDetail>(:final error):
        return Result.error(error);
    }
  }

  Future<Result<void>> _loadActionOptions() async {
    final users = await _userRepository.getAssignableUsers();
    if (users is Ok<List<User>>) {
      _assignableUsers = users.value;
    }

    final categories = await _categoryRepository.getCategories();
    if (categories is Ok<List<RequestCategory>>) {
      _categoryOptions = categories.value;
    }

    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _changeStatus(RequestStatus status) =>
      _patch(RequestPatch(status: status));

  Future<Result<void>> _changePriority(Priority priority) =>
      _patch(RequestPatch(priority: priority));

  Future<Result<void>> _assign(int? userId) =>
      _patch(RequestPatch(assigneeId: userId, unassign: userId == null));

  Future<Result<void>> _patch(RequestPatch patch) async {
    final result = await _requestRepository.updateRequest(requestId, patch);

    switch (result) {
      case Ok<RequestDetail>(:final value):
        _detail = value;
        notifyListeners();
        return const Result.ok(null);
      case Error<RequestDetail>(:final error):
        return Result.error(error);
    }
  }

  Future<Result<void>> _addComment(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return const Result.ok(null);

    final result = await _requestRepository.addComment(
      requestId,
      content: trimmed,
    );

    switch (result) {
      case Ok<Comment>(:final value):
        final current = _detail;
        if (current != null) {
          _detail = current.copyWith(comments: [...current.comments, value]);
          notifyListeners();
        }
        return const Result.ok(null);
      case Error<Comment>(:final error):
        return Result.error(error);
    }
  }

  @override
  void dispose() {
    load.dispose();
    loadActionOptions.dispose();
    changeStatus.dispose();
    changePriority.dispose();
    assign.dispose();
    addComment.dispose();
    super.dispose();
  }
}
