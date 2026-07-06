import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pop aman untuk GoRouter — hindari GoError saat stack kosong (web reload).
void safePop(BuildContext context, {required String fallback}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
