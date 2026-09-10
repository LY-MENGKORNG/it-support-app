// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Request _$RequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Request', json, ($checkedConvert) {
      final val = Request(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        title: $checkedConvert('title', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        category: $checkedConvert(
          'category',
          (v) => RequestCategory.fromJson(v as Map<String, dynamic>),
        ),
        priority: $checkedConvert(
          'priority',
          (v) => const PriorityConverter().fromJson(v as String),
        ),
        status: $checkedConvert(
          'status',
          (v) => const RequestStatusConverter().fromJson(v as String),
        ),
        requester: $checkedConvert(
          'requester',
          (v) => User.fromJson(v as Map<String, dynamic>),
        ),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => const LocalDateTime().fromJson(v as String),
        ),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => const LocalDateTime().fromJson(v as String),
        ),
        assignee: $checkedConvert(
          'assignee',
          (v) => v == null ? null : User.fromJson(v as Map<String, dynamic>),
        ),
        resolvedAt: $checkedConvert(
          'resolvedAt',
          (v) => const LocalDateTimeOrNull().fromJson(v as String?),
        ),
        closedAt: $checkedConvert(
          'closedAt',
          (v) => const LocalDateTimeOrNull().fromJson(v as String?),
        ),
      );
      return val;
    });

RequestPage _$RequestPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RequestPage', json, ($checkedConvert) {
      final val = RequestPage(
        items: $checkedConvert(
          'items',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => Request.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        ),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        hasMore: $checkedConvert('hasMore', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$NewRequestToJson(NewRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'categoryId': instance.categoryId,
      'priority': const PriorityConverter().toJson(instance.priority),
      'assigneeId': ?instance.assigneeId,
    };
