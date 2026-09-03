import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/utils/result.dart';

class SharedPreferencesService {
  const SharedPreferencesService();

  static const _tokenKey = 'access_token';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Result<String?>> fetchToken() => Result.safeTryAsync(() async {
    return (await _prefs).getString(_tokenKey);
  });

  Future<Result<void>> saveToken(String token) => Result.safeTryAsync(() async {
    await (await _prefs).setString(_tokenKey, token);
  });

  Future<Result<void>> removeToken() => Result.safeTryAsync(() async {
    await (await _prefs).remove(_tokenKey);
  });
}
