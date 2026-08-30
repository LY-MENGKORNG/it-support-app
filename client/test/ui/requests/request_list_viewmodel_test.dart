import 'package:flutter_test/flutter_test.dart';

import 'package:app/domain/models/request_filters.dart';
import 'package:app/domain/models/request_status.dart';
import 'package:app/ui/requests/view_models/request_list_viewmodel.dart';

import '../../fakes/fixtures.dart';
import '../../fakes/repositories/fake_category_repository.dart';
import '../../fakes/repositories/fake_request_repository.dart';

void main() {
  late FakeRequestRepository requests;
  late FakeCategoryRepository categories;

  RequestListViewModel build() => RequestListViewModel(
    requestRepository: requests,
    categoryRepository: categories,
  );

  setUp(() {
    requests = FakeRequestRepository(
      requests: [
        buildRequest(id: 1),
        buildRequest(id: 2, status: RequestStatus.closed),
      ],
    );
    categories = FakeCategoryRepository();
  });

  group('load', () {
    // The view model runs `load` in its constructor, so a test only has to
    // wait for it — that is the pattern the architecture guide uses.
    test('populates items on construction', () async {
      final viewModel = build();
      addTearDown(viewModel.dispose);

      await viewModel.load.execute();

      expect(viewModel.items, hasLength(2));
      expect(viewModel.total, 2);
      expect(viewModel.load.completed, isTrue);
      expect(viewModel.load.error, isFalse);
    });

    // The Command replaces the hand-rolled isLoading/error pair that used to
    // get out of sync — this is the regression test for the original bug where
    // a finished load never notified and the spinner stayed forever.
    test('reports running, then completed', () async {
      final viewModel = build();
      addTearDown(viewModel.dispose);

      // The constructor already kicked `load` off, and a Command ignores
      // `execute()` while it is running — so let that first run finish before
      // observing the next one.
      await pumpEventQueue();

      final states = <bool>[];
      viewModel.load.addListener(() => states.add(viewModel.load.running));

      await viewModel.load.execute();

      expect(states, [true, false]);
      expect(viewModel.load.running, isFalse);
    });

    test('a failure is captured on the command, not thrown', () async {
      requests.error = Exception('boom');
      final viewModel = build();
      addTearDown(viewModel.dispose);

      await viewModel.load.execute();

      expect(viewModel.load.error, isTrue);
      expect(viewModel.load.exception, isNotNull);
      expect(viewModel.isEmpty, isTrue);
    });
  });

  group('paging', () {
    test('loadMore appends the next page', () async {
      requests = FakeRequestRepository(
        requests: List.generate(25, (index) => buildRequest(id: index + 1)),
      );
      final viewModel = build();
      addTearDown(viewModel.dispose);

      await viewModel.load.execute();
      expect(viewModel.items, hasLength(20));
      expect(viewModel.hasMore, isTrue);

      await viewModel.loadMore.execute();

      expect(viewModel.items, hasLength(25));
      expect(viewModel.hasMore, isFalse);
    });

    test('loadMore does nothing when there is no next page', () async {
      final viewModel = build();
      addTearDown(viewModel.dispose);
      await viewModel.load.execute();

      final before = requests.receivedFilters.length;
      await viewModel.loadMore.execute();

      expect(requests.receivedFilters.length, before);
    });
  });

  group('filters', () {
    test('applying a filter resets to the first page', () async {
      final viewModel = build();
      addTearDown(viewModel.dispose);
      await viewModel.load.execute();

      viewModel.applyFilters(
        const RequestFilters(status: RequestStatus.closed, offset: 60),
      );
      await pumpEventQueue();

      expect(viewModel.isFiltering, isTrue);
      expect(requests.receivedFilters.last.status, RequestStatus.closed);
      expect(requests.receivedFilters.last.offset, 0);
      expect(viewModel.items, hasLength(1));
    });

    test('clearFilters drops every narrowing parameter', () async {
      final viewModel = build();
      addTearDown(viewModel.dispose);

      viewModel.applyFilters(
        const RequestFilters(status: RequestStatus.closed),
      );
      await pumpEventQueue();
      viewModel.clearFilters();
      await pumpEventQueue();

      expect(viewModel.isFiltering, isFalse);
      expect(requests.receivedFilters.last.status, isNull);
    });
  });

  group('replace', () {
    test('swaps an updated row in place', () async {
      final viewModel = build();
      addTearDown(viewModel.dispose);
      await viewModel.load.execute();

      viewModel.replace(buildRequest(id: 1, assignee: kStaff));

      expect(viewModel.items, hasLength(2));
      expect(viewModel.items.first.assignee, kStaff);
    });

    test(
      'drops a row that no longer matches the active status filter',
      () async {
        final viewModel = build();
        addTearDown(viewModel.dispose);
        await pumpEventQueue();

        viewModel.applyFilters(
          const RequestFilters(status: RequestStatus.open),
        );
        await pumpEventQueue();
        expect(viewModel.items, hasLength(1));

        // The row was resolved elsewhere, so it no longer belongs in an
        // "open only" list.
        viewModel.replace(buildRequest(id: 1, status: RequestStatus.resolved));

        expect(viewModel.items, isEmpty);
      },
    );
  });
}
