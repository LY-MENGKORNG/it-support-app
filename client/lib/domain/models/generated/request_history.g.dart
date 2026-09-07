// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../request_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestHistory _$RequestHistoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RequestHistory', json, ($checkedConvert) {
      final val = RequestHistory(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        requestId: $checkedConvert('requestId', (v) => (v as num).toInt()),
        action: $checkedConvert(
          'action',
          (v) => const RequestHistoryActionConverter().fromJson(v as String),
        ),
        actor: $checkedConvert(
          'user',
          (v) => User.fromJson(v as Map<String, dynamic>),
        ),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => const LocalDateTime().fromJson(v as String),
        ),
        oldValue: $checkedConvert('oldValue', (v) => v as String?),
        newValue: $checkedConvert('newValue', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'actor': 'user'});
