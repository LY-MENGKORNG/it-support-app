import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/models/user_role.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';

class UserListViewModel extends ChangeNotifier {
  UserListViewModel({required this._userRepository}) {
    load = Command0(_load)..execute();
  }

  final UserRepository _userRepository;

  late final Command0<void> load;

  List<User> _items = const [];
  UserRole? _role;
  String _query = '';
  Timer? _debounce;
  bool _reloadQueued = false;

  UnmodifiableListView<User> get users => UnmodifiableListView(_items);
  UserRole? get role => _role;
  bool get isEmpty => _items.isEmpty;

  void search(String query) {
    _debounce?.cancel();
    // NOTE: Sleep for 350 ms before refreshing.
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _query = query;
      _refresh();
    });
  }

  void filterByRole(UserRole? role) {
    _role = role;
    _refresh();
  }

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
    final result = await _userRepository.getUsers(
      query: _query,
      role: _role,
      limit: 100,
    );

    switch (result) {
      case Ok<List<User>>(:final value):
        _items = value;
        notifyListeners();
        return const Result.ok(null);
      case Error<List<User>>(:final error):
        _items = const [];
        notifyListeners();
        return Result.error(error);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    load.dispose();
    super.dispose();
  }
}
