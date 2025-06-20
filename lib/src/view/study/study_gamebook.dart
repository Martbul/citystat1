import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citystat1/src/model/common/id.dart';
import 'package:citystat1/src/model/study/study_controller.dart';
import 'package:citystat1/src/utils/l10n_context.dart';
import 'package:url_launcher/url_launcher.dart';

class StudyGamebook extends StatelessWidget {
  const StudyGamebook(this.id);

  final StudyId id;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Comment(id: id),
          _Hint(id: id),
        ],
      ),
    );
  }
}

class _Comment extends ConsumerWidget {
  const _Comment({required this.id});

  final StudyId id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studyControllerProvider(id)).requireValue;

    final comment =
        state.gamebookComment ??
        switch (state.gamebookState) {
          GamebookState.findTheMove => context.l10n.studyWhatWouldYouPlay,
          GamebookState.correctMove => context.l10n.studyGoodMove,
          GamebookState.incorrectMove => context.l10n.puzzleNotTheMove,
          GamebookState.lessonComplete => context.l10n.studyYouCompletedThisLesson,
          _ => '',
        };

    return Expanded(
      child: Scrollbar(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Linkify(
              text: comment,
              style: const TextStyle(fontSize: 16),
              onOpen: (link) {
                launchUrl(Uri.parse(link.url));
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Hint extends ConsumerStatefulWidget {
  const _Hint({required this.id});

  final StudyId id;

  @override
  ConsumerState<_Hint> createState() => _HintState();
}

class _HintState extends ConsumerState<_Hint> {
  bool showHint = false;

  @override
  Widget build(BuildContext context) {
    final hint = ref.watch(studyControllerProvider(widget.id)).requireValue.gamebookHint;
    return hint == null
        ? const SizedBox.shrink()
        : SizedBox(
            height: 40,
            child: showHint
                ? Center(child: Text(hint))
                : TextButton(
                    onPressed: () {
                      setState(() {
                        showHint = true;
                      });
                    },
                    child: Text(context.l10n.getAHint),
                  ),
          );
  }
}

class GamebookButton extends StatelessWidget {
  const GamebookButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  final bool highlighted;

  bool get enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final primary = ColorScheme.of(context).primary;

    return Semantics(
      container: true,
      enabled: enabled,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: highlighted ? primary : null, size: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16.0, color: highlighted ? primary : null),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
