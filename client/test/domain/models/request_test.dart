import 'package:flutter_test/flutter_test.dart';

import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/domain/models/request_history_action.dart';
import 'package:app/domain/models/request_status.dart';

import '../../fakes/fixtures.dart';

void main() {
  group('Request.fromJson', () {
    test('parses a fully populated request', () {
      final request = Request.fromJson(
        requestJson(
          status: 'in_progress',
          priority: 'critical',
          assignee: userJson(),
          resolvedAt: '2026-08-22T10:00:00.000Z',
          closedAt: '2026-08-23T10:00:00.000Z',
        ),
      );

      expect(request.id, 42);
      expect(request.status, RequestStatus.inProgress);
      expect(request.priority, Priority.critical);
      expect(request.category.name, 'Network');
      expect(request.requester.name, 'Malis Tep');
      expect(request.assignee?.name, 'Bopha Lim');
      expect(request.isAssigned, isTrue);
      expect(request.resolvedAt, isNotNull);
      expect(request.closedAt, isNotNull);
    });

    test('treats a null assignee as unassigned rather than crashing', () {
      final request = Request.fromJson(requestJson());

      expect(request.assignee, isNull);
      expect(request.isAssigned, isFalse);
    });

    // The original code read `json['closedAt'] ? ... : null`, using the value
    // itself as the condition. That compiles (the field is `dynamic`) and then
    // throws at runtime as soon as a request is actually closed.
    test('parses a closed request without using the date as a condition', () {
      final request = Request.fromJson(
        requestJson(status: 'closed', closedAt: '2026-08-23T10:00:00.000Z'),
      );

      expect(request.status, RequestStatus.closed);
      expect(
        request.closedAt,
        DateTime.parse('2026-08-23T10:00:00.000Z').toLocal(),
      );
    });

    test('a missing required field names the field it failed on', () {
      final broken = requestJson()..remove('title');

      expect(
        () => Request.fromJson(broken),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('title'),
          ),
        ),
      );
    });
  });

  group('RequestDetail', () {
    test('parses comments and history alongside the request', () {
      final detail = RequestDetail.fromJson(
        requestDetailJson(
          comments: [
            commentJson(),
            commentJson(id: 2, content: 'Fixed.'),
          ],
          history: [
            historyJson(),
            historyJson(
              id: 2,
              action: 'created',
              oldValue: null,
              newValue: 'open',
            ),
          ],
        ),
      );

      expect(detail.id, 42);
      expect(detail.comments, hasLength(2));
      expect(detail.comments.last.content, 'Fixed.');
      expect(detail.history.first.action, RequestHistoryAction.statusChanged);
      expect(detail.history.last.action, RequestHistoryAction.created);
    });

    test('absent collections read as empty, not null', () {
      final detail = RequestDetail.fromJson(requestJson());

      expect(detail.comments, isEmpty);
      expect(detail.history, isEmpty);
    });
  });

  group('RequestPatch', () {
    test('omits fields that were not set', () {
      const patch = RequestPatch(status: RequestStatus.resolved);

      expect(patch.toJson(), {'status': 'resolved'});
    });

    // The actor used to ride along in the body. It comes from the access token
    // now, so a client cannot claim a change was made by someone else.
    test('carries no actor', () {
      expect(const RequestPatch(status: RequestStatus.closed).toJson(), {
        'status': 'closed',
      });
    });

    // An omitted key means "leave alone", so clearing an assignee has to send
    // an explicit null — these two cases must not serialise the same way.
    test('unassign sends an explicit null', () {
      expect(const RequestPatch(unassign: true).toJson(), {'assigneeId': null});
      expect(const RequestPatch().toJson(), isEmpty);
      expect(const RequestPatch(assigneeId: 9).toJson(), {'assigneeId': 9});
    });
  });

  group('NewRequest', () {
    test('carries no requester', () {
      const draft = NewRequest(
        title: 'Wi-Fi drops',
        description: 'Every afternoon.',
        categoryId: 3,
        priority: Priority.high,
      );

      expect(draft.toJson(), {
        'title': 'Wi-Fi drops',
        'description': 'Every afternoon.',
        'categoryId': 3,
        'priority': 'high',
      });
    });
  });

  group('RequestFilters', () {
    test('leaves unset filters out of the query string', () {
      final params = const RequestFilters().toQueryParameters();

      expect(params.containsKey('status'), isFalse);
      expect(params.containsKey('q'), isFalse);
      expect(params['sort'], 'newest');
      expect(params['limit'], 20);
    });

    test('serialises the filters that are set', () {
      final params = const RequestFilters(
        query: '  wifi  ',
        status: RequestStatus.inProgress,
        priority: Priority.high,
        categoryId: 3,
        unassignedOnly: true,
        offset: 40,
      ).toQueryParameters();

      expect(params['q'], 'wifi');
      expect(params['status'], 'in_progress');
      expect(params['priority'], 'high');
      expect(params['categoryId'], 3);
      expect(params['unassigned'], 'true');
      expect(params['offset'], 40);
    });

    test('copyWith needs an explicit flag to clear a field', () {
      const filters = RequestFilters(status: RequestStatus.open, query: 'x');

      // Passing null means "keep", which is why clearing needs its own flag.
      expect(filters.copyWith().status, RequestStatus.open);
      expect(filters.copyWith(clearStatus: true).status, isNull);
      expect(filters.copyWith(clearQuery: true).isFiltering, isTrue);
      expect(
        filters.copyWith(clearStatus: true, clearQuery: true).isFiltering,
        isFalse,
      );
    });
  });
}
