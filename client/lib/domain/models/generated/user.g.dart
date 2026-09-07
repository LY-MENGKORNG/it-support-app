// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('User', json, ($checkedConvert) {
      final val = User(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        role: $checkedConvert(
          'role',
          (v) => const UserRoleConverter().fromJson(v as String),
        ),
        isActive: $checkedConvert('isActive', (v) => v as bool? ?? true),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => const LocalDateTimeOrNull().fromJson(v as String?),
        ),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => const LocalDateTimeOrNull().fromJson(v as String?),
        ),
      );
      return val;
    });
