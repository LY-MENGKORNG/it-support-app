import 'package:flutter_test/flutter_test.dart';

import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request_history_action.dart';
import 'package:app/domain/models/request_status.dart';
import 'package:app/domain/models/user_role.dart';

void main() {
  group('wire mapping', () {
    // The bug these enums were designed to prevent: the API sends
    // `in_progress`, and `values.byName('in_progress')` throws because the Dart
    // constant is named `inProgress`.
    test('RequestStatus maps snake_case wire values to Dart names', () {
      expect(RequestStatus.fromWire('in_progress'), RequestStatus.inProgress);
      expect(RequestStatus.inProgress.wire, 'in_progress');
      expect(RequestStatus.inProgress.label, 'In Progress');
    });

    test('every value round-trips through its wire string', () {
      for (final status in RequestStatus.values) {
        expect(RequestStatus.fromWire(status.wire), status);
      }
      for (final priority in Priority.values) {
        expect(Priority.fromWire(priority.wire), priority);
      }
      for (final action in RequestHistoryAction.values) {
        expect(RequestHistoryAction.fromWire(action.wire), action);
      }
      for (final role in UserRole.values) {
        expect(UserRole.fromWire(role.wire), role);
      }
    });

    test('an unknown value fails loudly instead of silently', () {
      expect(
        () => RequestStatus.fromWire('archived'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('domain rules', () {
    test('priorities rank in order', () {
      expect(Priority.critical.rank, greaterThan(Priority.high.rank));
      expect(Priority.high.rank, greaterThan(Priority.medium.rank));
      expect(Priority.medium.rank, greaterThan(Priority.low.rank));
    });

    test('a settled request can be reopened', () {
      expect(RequestStatus.resolved.nextOptions, contains(RequestStatus.open));
      expect(RequestStatus.closed.nextOptions, contains(RequestStatus.open));
      expect(RequestStatus.resolved.isSettled, isTrue);
      expect(RequestStatus.open.isSettled, isFalse);
    });

    test('an open request cannot jump straight to closed', () {
      expect(
        RequestStatus.open.nextOptions,
        isNot(contains(RequestStatus.closed)),
      );
    });

    test('only staff and admins can manage requests', () {
      expect(UserRole.employee.isSupportStaff, isFalse);
      expect(UserRole.staff.isSupportStaff, isTrue);
      expect(UserRole.admin.isSupportStaff, isTrue);
    });
  });
}
