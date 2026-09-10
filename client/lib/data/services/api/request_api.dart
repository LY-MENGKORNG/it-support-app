import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_detail.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/api.dart';

class RequestApi {
  final RestClient _client;

  static const _path = '/request';

  const RequestApi(this._client);

  Future<Result<RequestPage>> list(RequestFilters filters) {
    return _client.get(
      _path,
      asObject(RequestPage.fromJson),
      query: filters.toQueryParameters(),
    );
  }

  Future<Result<RequestDetail>> get(int id) {
    return _client.get('$_path/$id', asObject(RequestDetail.fromJson));
  }

  Future<Result<RequestDetail>> create(NewRequest draft) {
    return _client.post(
      _path,
      asObject(RequestDetail.fromJson),
      body: draft.toJson(),
    );
  }

  Future<Result<RequestDetail>> update(int id, RequestPatch patch) {
    return _client.patch(
      '$_path/$id',
      asObject(RequestDetail.fromJson),
      body: patch.toJson(),
    );
  }
}
