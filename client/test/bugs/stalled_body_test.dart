import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:app/data/services/api/rest_client.dart';

/// `_payload` puts `.timeout()` on `_client.send(...)` only. Reading the body
/// with `http.Response.fromStream` is left outside it, so a server that sends
/// headers and then stalls leaves the call hanging with no deadline at all.
void main() {
  test('a stalled response body never times out', () async {
    final stalled = StreamController<List<int>>();
    addTearDown(stalled.close);

    final client = RestClient(
      client: _StalledClient(stalled.stream),
      baseUrl: 'http://test',
      timeout: const Duration(milliseconds: 100),
    );

    var finished = false;
    unawaited(
      client.get<Object?>('/requests', (p) => p).then((_) => finished = true),
    );

    // Ten times the configured timeout.
    await Future<void>.delayed(const Duration(seconds: 1));

    expect(
      finished,
      isTrue,
      reason: 'the 100ms timeout should have fired long ago',
    );
  });
}

class _StalledClient extends http.BaseClient {
  _StalledClient(this._body);

  final Stream<List<int>> _body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      // Headers arrive immediately; the body never does.
      http.StreamedResponse(_body, 200);
}
