import 'package:flutter/material.dart';

/// Single-choice scenario selector used by the demo screens — a wrapping row
/// of FilterChips. Selected chip renders accent-on-dark via the demo theme's
/// secondaryContainer mapping; nothing to style here.
class ScenarioChips extends StatelessWidget {
  const ScenarioChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          for (var i = 0; i < labels.length; i++)
            FilterChip(
              selected: i == selected,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              labelStyle: const TextStyle(fontSize: 12),
              label: Text(labels[i]),
              onSelected: (_) => onSelected(i),
            ),
        ],
      ),
    );
  }
}
