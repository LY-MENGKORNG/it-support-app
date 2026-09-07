// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Session _$SessionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Session', json, ($checkedConvert) {
      final val = Session(
        accessToken: $checkedConvert('accessToken', (v) => v as String),
        user: $checkedConvert(
          'user',
          (v) => User.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });
