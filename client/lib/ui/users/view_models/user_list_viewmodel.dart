import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/models/user_role.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/debounced_refresh.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/safe_notifier.dart';

class UserListViewModel extends ChangeNotifier with SafeNotifier {
  UserListViewModel({required this._userRepository}) {
    load = Command0(_load)..execute();
    _refresh = DebouncedRefresh(load);
  }

  final UserRepository _userRepository;

  late final Command0<void> load;

  late final DebouncedRefresh _refresh;

  List<User> _items = const [];
  UserRole? _role;
  String _query = '';

  UnmodifiableListView<User> get users => UnmodifiableListView(_items);
  UserRole? get role => _role;
  bool get isEmpty => _items.isEmpty;

  void search(String query) => _refresh.schedule(() => _query = query);

  void filterByRole(UserRole? role) {
    _role = role;
    _refresh.now();
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
    _refresh.cancel();
    load.dispose();
    super.dispose();
  }
}
