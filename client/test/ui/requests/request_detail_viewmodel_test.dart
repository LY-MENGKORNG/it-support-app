import 'package:flutter_test/flutter_test.dart';

import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request_status.dart';
import 'package:app/ui/requests/view_models/request_detail_viewmodel.dart';

import '../../fakes/fixtures.dart';
import '../../fakes/repositories/fake_category_repository.dart';
import '../../fakes/repositories/fake_request_repository.dart';
import '../../fakes/repositories/fake_session_repository.dart';
import '../../fakes/repositories/fake_user_repository.dart';

void main() {
  late FakeRequestRepository requests;
  late FakeSessionRepository session;

  RequestDetailViewModel build({int id = 1}) => RequestDetailViewModel(
    requestRepository: requests,
    userRepository: FakeUserRepository(),
    categoryRepository: FakeCategoryRepository(),
    sessionRepository: session,
    requestId: id,
  );

  setUp(() {
    requests = FakeRequestRepository(requests: [buildRequest(id: 1)]);
    session = FakeSessionRepository(user: kStaff);
  });

  test('loads the request', () async {
    final viewModel = build();
    addTearDown(viewModel.dispose);

    await pumpEventQueue();

    expect(viewModel.request?.id, 1);
    expect(viewModel.load.completed, isTrue);
  });

  test('staff can manage; an employee cannot', () async {
    session = FakeSessionRepository(user: kEmployee);
    final viewModel = build();
    addTearDown(viewModel.dispose);

    expect(viewModel.canManage, isFalse);
  });

  test('changing status updates the record through the repository', () async {
    final viewModel = build();
    addTearDown(viewModel.dispose);
    await pumpEventQueue();

    await viewModel.changeStatus.execute(RequestStatus.resolved);

    expect(viewModel.changeStatus.completed, isTrue);
    expect(viewModel.request?.status, RequestStatus.resolved);
  });

  test('changing priority updates the record', () async {
    final viewModel = build();
    addTearDown(viewModel.dispose);
    await pumpEventQueue();

    await viewModel.changePriority.execute(Priority.low);

    expect(viewModel.request?.priority, Priority.low);
  });

  test('assigning null unassigns', () async {
    requests = FakeRequestRepository(
      requests: [buildRequest(id: 1, assignee: kStaff)],
    );
    final viewModel = build();
    addTearDown(viewModel.dispose);
    await pumpEventQueue();
    expect(viewModel.request?.assignee, isNotNull);

    await viewModel.assign.execute(null);

    expect(viewModel.request?.assignee, isNull);
  });

  test('a comment is appended to the thread', () async {
    final viewModel = build();
    addTearDown(viewModel.dispose);
    await pumpEventQueue();
    expect(viewModel.detail?.comments, isEmpty);

    await viewModel.addComment.execute('Looking into it.');

    expect(viewModel.detail?.comments, hasLength(1));
    expect(viewModel.detail?.comments.first.content, 'Looking into it.');
  });

  test('a failed mutation leaves the record intact', () async {
    final viewModel = build();
    addTearDown(viewModel.dispose);
    await pumpEventQueue();

    requests.error = Exception('server exploded');
    await viewModel.changeStatus.execute(RequestStatus.closed);

    expect(viewModel.changeStatus.error, isTrue);
    // The screen keeps showing the record rather than blanking out.
    expect(viewModel.request?.status, RequestStatus.open);
  });
}
