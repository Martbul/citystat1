import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citystat1/src/model/engine/evaluation_preferences.dart';
import 'package:citystat1/src/model/engine/evaluation_service.dart';
import 'package:citystat1/src/utils/l10n_context.dart';
import 'package:citystat1/src/widgets/list.dart';
import 'package:citystat1/src/widgets/non_linear_slider.dart';
import 'package:citystat1/src/widgets/settings.dart';

class EngineSettingsWidget extends ConsumerWidget {
  const EngineSettingsWidget({
    this.onToggleLocalEvaluation,
    required this.onSetEngineSearchTime,
    required this.onSetNumEvalLines,
    required this.onSetEngineCores,
    super.key,
  });

  final VoidCallback? onToggleLocalEvaluation;
  final void Function(Duration) onSetEngineSearchTime;
  final void Function(int) onSetNumEvalLines;
  final void Function(int) onSetEngineCores;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(engineEvaluationPreferencesProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onToggleLocalEvaluation != null)
          ListSection(
            children: [
              SwitchSettingTile(
                title: Text(context.l10n.toggleLocalEvaluation),
                value: prefs.isEnabled,
                onChanged: (_) {
                  onToggleLocalEvaluation!.call();
                },
              ),
            ],
          ),
        ListSection(
          header: const SettingsSectionTitle('Stockfish'),
          children: [
            ListTile(
              title: Text.rich(
                TextSpan(
                  text: 'Search time: ',
                  style: const TextStyle(fontWeight: FontWeight.normal),
                  children: [
                    TextSpan(
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      text: prefs.engineSearchTime.inSeconds == 3600
                          ? '∞'
                          : '${prefs.engineSearchTime.inSeconds}s',
                    ),
                  ],
                ),
              ),
              subtitle: NonLinearSlider(
                labelBuilder: (value) => value == 3600 ? '∞' : '${value}s',
                value: prefs.engineSearchTime.inSeconds,
                values: kAvailableEngineSearchTimes.map((e) => e.inSeconds).toList(),
                onChangeEnd: (value) => onSetEngineSearchTime(Duration(seconds: value.toInt())),
              ),
            ),
            ListTile(
              title: Text.rich(
                TextSpan(
                  text: '${context.l10n.multipleLines}: ',
                  style: const TextStyle(fontWeight: FontWeight.normal),
                  children: [
                    TextSpan(
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      text: prefs.numEvalLines.toString(),
                    ),
                  ],
                ),
              ),
              subtitle: NonLinearSlider(
                value: prefs.numEvalLines,
                values: const [0, 1, 2, 3],
                onChangeEnd: (value) => onSetNumEvalLines(value.toInt()),
              ),
            ),
            if (maxEngineCores > 1)
              ListTile(
                title: Text.rich(
                  TextSpan(
                    text: '${context.l10n.cpus}: ',
                    style: const TextStyle(fontWeight: FontWeight.normal),
                    children: [
                      TextSpan(
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        text: prefs.numEngineCores.toString(),
                      ),
                    ],
                  ),
                ),
                subtitle: NonLinearSlider(
                  value: prefs.numEngineCores,
                  values: List.generate(maxEngineCores, (index) => index + 1),
                  onChangeEnd: (value) => onSetEngineCores(value.toInt()),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
