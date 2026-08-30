import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/utils/result.dart';

/// The app's key-value storage data source.
///
/// A second service alongside `ApiClient`, because it is a second external
/// source. It returns [Result] for the same reason: a disk read can fail, and
/// the caller should not have to remember that.
///
/// It stores the *access token* and nothing else. The token already says who
/// you are — caching a copy of the user next to it would only create a second
/// answer to that question, free to drift from the first.
class SharedPreferencesService {
  const SharedPreferencesService();

  static const _tokenKey = 'access_token';

  Future<Result<String?>> fetchToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Result.ok(prefs.getString(_tokenKey));
    } on Exception catch (exception) {
      return Result.error(exception);
    }
  }

  Future<Result<void>> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      return const Result.ok(null);
    } on Exception catch (exception) {
      return Result.error(exception);
    }
  }

  Future<Result<void>> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      return const Result.ok(null);
    } on Exception catch (exception) {
      return Result.error(exception);
    }
  }
}
