// lib/shared/platform/browser_bridge.dart
// Browser notifications and file download. Real implementation on web,
// no-op elsewhere so mobile builds still compile.

export 'browser_bridge_stub.dart'
    if (dart.library.js_interop) 'browser_bridge_web.dart';
