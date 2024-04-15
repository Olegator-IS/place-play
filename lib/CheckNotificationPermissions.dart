import 'package:permission_handler/permission_handler.dart';

class CheckNotificationPermissions {
  Future<bool> checkNotificationPermission() async {
    PermissionStatus status = await Permission.notification.status;
    return status.isGranted;
  }
}
