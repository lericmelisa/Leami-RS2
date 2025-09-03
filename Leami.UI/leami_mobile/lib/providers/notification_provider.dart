import 'package:leami_mobile/models/notification.dart';
import 'package:leami_mobile/providers/base_provider.dart';

class NotificationProvider extends BaseProvider<NotificationModel> {
  NotificationProvider() : super('Notification');

  @override
  NotificationModel fromJson(dynamic json) {
    return NotificationModel.fromJson(json);
  }
}
