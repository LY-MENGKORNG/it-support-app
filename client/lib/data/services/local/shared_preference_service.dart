import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/utils/result.dart';

/// 🛠️ A service for managing shared preferences, specifically for storing and retrieving the access token.
class SharedPreferencesService {
  final String _tokenKey;

  const SharedPreferencesService(this._tokenKey);

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Result<String?>> fetchToken() {
    return Result.safeTryAsync(() async {
      final prefs = await _prefs;
      return prefs.getString(_tokenKey);
    });
  }

  Future<Result<void>> saveToken(String token) {
    return Result.safeTryAsync(() async {
      final prefs = await _prefs;
      await prefs.setString(_tokenKey, token);
    });
  }

  Future<Result<void>> removeToken() {
    return Result.safeTryAsync(() async {
      final prefs = await _prefs;
      await prefs.remove(_tokenKey);
    });
  }
}
