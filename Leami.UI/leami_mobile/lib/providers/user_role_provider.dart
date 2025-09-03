

import 'package:leami_mobile/models/user_role.dart';
import 'package:leami_mobile/providers/base_provider.dart';

class UserRoleProvider extends BaseProvider<UserRole> {
  UserRoleProvider() : super("Role");

  @override
  UserRole fromJson(dynamic json) {
    return UserRole.fromJson(json);
  }
}
