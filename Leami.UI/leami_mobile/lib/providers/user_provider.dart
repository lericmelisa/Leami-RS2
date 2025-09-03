import 'package:leami_mobile/models/user.dart';
import 'package:leami_mobile/providers/base_provider.dart';

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("User");

  @override
  User fromJson(dynamic json) {
    return User.fromJson(json);
  }
}
