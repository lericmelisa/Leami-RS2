import 'package:leami_desktop/models/user_role.dart';
import 'package:leami_desktop/providers/base_provider.dart';

class UserRoleProvider extends BaseProvider<UserRole> {
  UserRoleProvider() : super("Role");

  @override
  UserRole fromJson(dynamic json) {
    return UserRole.fromJson(json);
  }
}
