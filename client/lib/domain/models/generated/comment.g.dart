// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Comment', json, ($checkedConvert) {
      final val = Comment(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        requestId: $checkedConvert('requestId', (v) => (v as num).toInt()),
        content: $checkedConvert('content', (v) => v as String),
        author: $checkedConvert(
          'user',
          (v) => User.fromJson(v as Map<String, dynamic>),
        ),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => const LocalDateTime().fromJson(v as String),
        ),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => const LocalDateTimeOrNull().fromJson(v as String?),
        ),
      );
      return val;
    }, fieldKeyMap: const {'author': 'user'});
