import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/utils/result.dart';

import 'rest_client.dart';

class RequestApi {
  const RequestApi(this._client);

  final RestClient _client;

  static const _path = '/request';

  Future<Result<RequestPage>> list(RequestFilters filters) => _client.get(
    _path,
    asObject(RequestPage.fromJson),
    query: filters.toQueryParameters(),
  );

  Future<Result<RequestDetail>> get(int id) =>
      _client.get('$_path/$id', asObject(RequestDetail.fromJson));

  Future<Result<RequestDetail>> create(NewRequest draft) => _client.post(
    _path,
    asObject(RequestDetail.fromJson),
    body: draft.toJson(),
  );

  Future<Result<RequestDetail>> update(int id, RequestPatch patch) =>
      _client.patch(
        '$_path/$id',
        asObject(RequestDetail.fromJson),
        body: patch.toJson(),
      );
}
