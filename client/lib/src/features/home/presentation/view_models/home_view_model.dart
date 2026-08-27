import 'package:app/src/data/models/user_model.dart';
import 'package:app/src/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  HomeViewModel({required this._userRepository});

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _err;

  // Getters
  List<UserModel> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get err => _err;

  Future<void> loadUsers() async {
    _isLoading = true;
    _err = null;

    // Call this method whenever the object changes, to notify any clients the
    // object may have changed. Listeners that are added during this iteration
    // will not be visited. Listeners that are removed during this iteration will
    // not be visited after they are removed.
    notifyListeners();

    try {
      _users = await _userRepository.getUsers();
    } catch (e) {
      _err = 'Failed to load users';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }
}
