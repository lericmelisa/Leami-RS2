import 'package:json_annotation/json_annotation.dart';

part 'user_role.g.dart';

@JsonSerializable()
class UserRole {
  @JsonKey(name: 'roleid')
  int id;

  @JsonKey(name: 'roleName')
  String name;

  String? description;

  UserRole({this.id = 0, this.name = "", this.description = ""});

  factory UserRole.fromJson(Map<String, dynamic> json) =>
      _$UserRoleFromJson(json);

  Map<String, dynamic> toJson() => _$UserRoleToJson(this);
}
