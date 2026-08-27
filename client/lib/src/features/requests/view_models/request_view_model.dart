import 'package:app/src/data/models/request_model.dart';
import 'package:app/src/data/repositories/request_repository.dart';
import 'package:flutter/material.dart';

/// ---------------- test code -------------------------//
sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T unwrap() {
    return switch (this) {
      Ok(value: final value) => value,
      Err(error: final error) => throw Exception(
        'Called unwrap() on Err: $error',
      ),
    };
  }

  E unwrapErr() {
    return switch (this) {
      Ok() => throw Exception('Called unwrapErr() on Ok'),
      Err(error: final error) => error,
    };
  }
}

final class Ok<T, E> extends Result<T, E> {
  final T value;

  const Ok(this.value);
}

final class Err<T, E> extends Result<T, E> {
  final E error;

  const Err(this.error);
}

/// ---------------- test code -------------------------//

class RequestViewModel extends ChangeNotifier {
  final RequestRepository _requestRepo;

  RequestViewModel({required this._requestRepo});

  List<RequestModel> _requests = [];
  bool _isLoading = false;
  String? _err;

  List<RequestModel> get requests => List.unmodifiable(_requests);
  bool get isLoading => _isLoading;
  String? get err => _err;

  Future<void> getRequests() async {
    _err = null;
    _isLoading = true;

    notifyListeners();

    try {
      _requests = await _requestRepo.getRequests();
    } catch (e) {
      _err = 'failed to fetch requests!';
    } finally {
      _isLoading = false;
    }
  }
}
