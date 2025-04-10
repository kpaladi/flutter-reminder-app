import 'package:flutter/cupertino.dart';

import '../widgets/loading_overlay.dart';

Future<void> runWithLoadingDialog({
  required BuildContext context,
  required String message,
  required Future<void> Function() task,
}) async {
  // Schedule showing the dialog after current frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showLoadingDialog(context, message);
  });

  await Future.delayed(Duration.zero);

  try {
    await task();
  } finally {
    // Schedule hiding the dialog safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        hideLoadingDialog(context);
      }
    });
  }
}
