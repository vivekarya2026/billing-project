// go_back.dart — back / close for full-screen routes.
// A route opened directly (page reload, shared link, notification) has
// nothing beneath it to pop, so fall back to its parent screen.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void goBack(BuildContext context, {String fallback = '/bills'}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
