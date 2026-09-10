// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../request_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestDetail _$RequestDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RequestDetail', json, ($checkedConvert) {
      final val = RequestDetail(
        request: $checkedConvert(
          'request',
          (v) => Request.fromJson(v as Map<String, dynamic>),
          readValue: RequestDetail._wholePayload,
        ),
        comments: $checkedConvert(
          'comments',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        ),
        history: $checkedConvert(
          'history',
          (v) =>
              (v as List<dynamic>?)
                  ?.map(
                    (e) => RequestHistory.fromJson(e as Map<String, dynamic>),
                  )
                  .toList() ??
              [],
        ),
      );
      return val;
    });
