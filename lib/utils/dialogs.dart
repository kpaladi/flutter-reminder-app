import 'package:flutter/cupertino.dart';

import '../widgets/loading_overlay.dart';

Future<void> runWithLoadingDialog({
  required BuildContext context,
  required String message,
  required Future<void> Function() task,
}) async {
  showLoadingDialog(context, message);
  try {
    await task();
  } finally {
    if (context.mounted) {
      hideLoadingDialog(context);
    }
  }
}