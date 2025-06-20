import 'package:flutter/material.dart';
import 'package:citystat1/src/utils/l10n_context.dart';
import 'package:citystat1/src/widgets/platform_alert_dialog.dart';

class YesNoDialog extends StatelessWidget {
  const YesNoDialog({
    super.key,
    this.title,
    this.content,
    required this.onYes,
    required this.onNo,
    this.alignment,
  });

  final Widget? title;
  final Widget? content;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: title,
      content: content,
      actions: [
        PlatformDialogAction(onPressed: onNo, child: Text(context.l10n.no)),
        PlatformDialogAction(onPressed: onYes, child: Text(context.l10n.yes)),
      ],
    );
  }
}
