// Web implementation for browser_bridge.dart.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

bool _supported() {
  try {
    return web.window.has('Notification');
  } catch (_) {
    return false;
  }
}

String notificationPermission() {
  if (!_supported()) return 'unsupported';
  return web.Notification.permission;
}

Future<String> requestNotificationPermission() async {
  if (!_supported()) return 'unsupported';
  try {
    final result = await web.Notification.requestPermission().toDart;
    return result.toDart;
  } catch (_) {
    return notificationPermission();
  }
}

bool isPageHidden() => web.document.visibilityState == 'hidden';

void showBrowserNotification({
  required String title,
  required String body,
  required String tag,
  void Function()? onClick,
}) {
  if (notificationPermission() != 'granted') return;
  final n = web.Notification(
    title,
    web.NotificationOptions(body: body, tag: tag),
  );
  if (onClick != null) {
    n.onclick = ((web.Event _) {
      web.window.focus();
      n.close();
      onClick();
    }).toJS;
  }
}

bool downloadTextFile(String filename, String contents, String mimeType) {
  try {
    final blob = web.Blob(
      [contents.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final a = web.HTMLAnchorElement()
      ..href = url
      ..download = filename;
    web.document.body?.append(a);
    a.click();
    a.remove();
    web.URL.revokeObjectURL(url);
    return true;
  } catch (_) {
    return false;
  }
}
