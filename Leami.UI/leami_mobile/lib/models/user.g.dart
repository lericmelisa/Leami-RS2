// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num?)?.toInt() ?? 0,
  firstName: json['firstName'] as String? ?? "",
  lastName: json['lastName'] as String? ?? "",
  email: json['email'] as String? ?? "",
  username: json['username'] as String? ?? "",
  role: json['role'] == null
      ? null
      : UserRole.fromJson(json['role'] as Map<String, dynamic>),
  createdAt: User._fromJsonDate(json['createdAt']),
  lastLoginAt: User._fromJsonDate(json['lastLoginAt']),
  phoneNumber: json['phoneNumber'] as String? ?? "",
  token: json['token'] as String? ?? "",
  expiration: User._fromJsonDate(json['expiration']),
  userImage: json['userImage'] as String?,
  jobTitle: json['jobTitle'] as String? ?? "",
  hireDate: User._fromJsonDate(json['hireDate']),
  note: json['note'] as String? ?? "",
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'username': instance.username,
  'role': instance.role,
  'createdAt': User._toJsonDate(instance.createdAt),
  'lastLoginAt': User._toJsonDate(instance.lastLoginAt),
  'phoneNumber': instance.phoneNumber,
  'token': instance.token,
  'expiration': User._toJsonDate(instance.expiration),
  'jobTitle': instance.jobTitle,
  'hireDate': User._toJsonDate(instance.hireDate),
  'note': instance.note,
  'userImage': instance.userImage,
};
