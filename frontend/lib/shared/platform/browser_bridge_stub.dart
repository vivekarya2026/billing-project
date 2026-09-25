// Non-web fallback for browser_bridge.dart.

/// "granted", "denied", "default", or "unsupported".
String notificationPermission() => 'unsupported';

Future<String> requestNotificationPermission() async => 'unsupported';

bool isPageHidden() => false;

void showBrowserNotification({
  required String title,
  required String body,
  required String tag,
  void Function()? onClick,
}) {}

bool downloadTextFile(String filename, String contents, String mimeType) => false;
