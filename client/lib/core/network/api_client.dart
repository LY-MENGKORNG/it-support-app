import 'package:http/http.dart' as http;

typedef Headers = Map<String, String>;
typedef Body = Object;

class ApiClient {
  static const String baseUrl = "http://localhost:3000";
  final http.Client _client;

  ApiClient({required this._client});

  Future<http.Response> get(String path, {Headers? headers}) {
    return _client.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  Future<http.Response> post(String path, {Headers? headers, Body? body}) {
    return _client.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body,
    );
  }

  void dispose() {
    _client.close();
  }
}
