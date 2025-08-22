// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRole _$UserRoleFromJson(Map<String, dynamic> json) => UserRole(
  id: (json['roleid'] as num?)?.toInt(),
  name: json['roleName'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$UserRoleToJson(UserRole instance) => <String, dynamic>{
  'roleid': instance.id,
  'roleName': instance.name,
  'description': instance.description,
};
