/// Sample API payloads and domain objects shared across tests.
///
/// One place for them means a change to the API contract breaks in a single
/// file rather than in every test that happens to build a request.
library;

import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_category.dart';
import 'package:app/domain/models/request_status.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/models/user_role.dart';

// --------------------------------------------------------------- JSON shapes

Map<String, dynamic> userJson({
  int id = 7,
  String name = 'Bopha Lim',
  String role = 'staff',
}) => {
  'id': id,
  'name': name,
  'email': 'bopha.lim@example.com',
  'role': role,
  'isActive': true,
  'createdAt': '2026-01-05T09:00:00.000Z',
  'updatedAt': '2026-01-05T09:00:00.000Z',
};

Map<String, dynamic> categoryJson({int id = 3, String name = 'Network'}) => {
  'id': id,
  'name': name,
};

Map<String, dynamic> requestJson({
  int id = 42,
  String status = 'open',
  String priority = 'high',
  Map<String, dynamic>? assignee,
  String? resolvedAt,
  String? closedAt,
}) => {
  'id': id,
  'title': 'Laptop cannot connect to Wi-Fi',
  'description': 'Fails at obtaining IP address.',
  'priority': priority,
  'status': status,
  'createdAt': '2026-08-20T10:00:00.000Z',
  'updatedAt': '2026-08-21T10:00:00.000Z',
  'resolvedAt': resolvedAt,
  'closedAt': closedAt,
  'categoryId': 3,
  'requesterId': 11,
  'assigneeId': assignee?['id'],
  'category': categoryJson(),
  'requester': userJson(id: 11, name: 'Malis Tep', role: 'employee'),
  'assignee': assignee,
};

Map<String, dynamic> requestDetailJson({
  String status = 'open',
  List<Map<String, dynamic>> comments = const [],
  List<Map<String, dynamic>> history = const [],
}) => {
  ...requestJson(status: status),
  'comments': comments,
  'history': history,
};

Map<String, dynamic> commentJson({int id = 1, String content = 'On it.'}) => {
  'id': id,
  'requestId': 42,
  'content': content,
  'createdAt': '2026-08-21T11:00:00.000Z',
  'updatedAt': null,
  'user': userJson(),
};

Map<String, dynamic> historyJson({
  int id = 1,
  String action = 'status_changed',
  String? oldValue = 'open',
  String? newValue = 'in_progress',
}) => {
  'id': id,
  'requestId': 42,
  'action': action,
  'oldValue': oldValue,
  'newValue': newValue,
  'createdAt': '2026-08-21T11:05:00.000Z',
  'user': userJson(),
};

Map<String, dynamic> pageJson(
  List<Map<String, dynamic>> items, {
  int? total,
  int offset = 0,
  bool? hasMore,
}) => {
  'items': items,
  'total': total ?? items.length,
  'limit': 20,
  'offset': offset,
  'hasMore': hasMore ?? false,
};

// ------------------------------------------------------------ domain objects

const kEmployee = User(
  id: 11,
  name: 'Malis Tep',
  email: 'malis.tep@example.com',
  role: UserRole.employee,
);

const kStaff = User(
  id: 7,
  name: 'Bopha Lim',
  email: 'bopha.lim@example.com',
  role: UserRole.staff,
);

const kCategory = RequestCategory(id: 3, name: 'Network');

Request buildRequest({
  int id = 42,
  RequestStatus status = RequestStatus.open,
  Priority priority = Priority.high,
  User? assignee,
}) => Request(
  id: id,
  title: 'Laptop cannot connect to Wi-Fi',
  description: 'Fails at obtaining IP address.',
  category: kCategory,
  priority: priority,
  status: status,
  requester: kEmployee,
  assignee: assignee,
  createdAt: DateTime.utc(2026, 8, 20, 10),
  updatedAt: DateTime.utc(2026, 8, 21, 10),
);

RequestDetail buildDetail({
  int id = 42,
  RequestStatus status = RequestStatus.open,
  User? assignee,
}) => RequestDetail(
  request: buildRequest(id: id, status: status, assignee: assignee),
  comments: const [],
  history: const [],
);
