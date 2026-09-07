// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../request_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestCategory _$RequestCategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RequestCategory', json, ($checkedConvert) {
      final val = RequestCategory(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String?),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => const LocalDateTimeOrNull().fromJson(v as String?),
        ),
      );
      return val;
    });
