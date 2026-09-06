import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/utils/result.dart';

class SharedPreferencesService {
  const SharedPreferencesService();

  static const _tokenKey = 'access_token';

  Future<Result<String?>> fetchToken() => Result.safeTryAsync(() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(_tokenKey);
  });

  Future<Result<void>> saveToken(String token) => Result.safeTryAsync(() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_tokenKey, token);
  });

  Future<Result<void>> removeToken() => Result.safeTryAsync(() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_tokenKey);
  });
}
