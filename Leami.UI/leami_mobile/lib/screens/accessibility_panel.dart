import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'accessibility_settings.dart';

class AccessibilityPanel extends StatelessWidget {
  const AccessibilityPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AccessibilitySettings>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pristupačnost',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text('Veličina teksta (${settings.textScale.toStringAsFixed(1)}x)'),
            Slider(
              value: settings.textScale,
              min: 1.0,
              max: 2.0,
              divisions: 4,
              label: '${(settings.textScale * 100).round()}%',
              onChanged: (v) =>
                  context.read<AccessibilitySettings>().setTextScale(v),
            ),
            const SizedBox(height: 8),
            Text(
              'Razmak između redova '
              '(${settings.lineHeight.toStringAsFixed(1)}x)',
            ),
            Slider(
              value: settings.lineHeight,
              min: 1.0,
              max: 1.8,
              divisions: 4,
              label: settings.lineHeight.toStringAsFixed(1),
              onChanged: (v) =>
                  context.read<AccessibilitySettings>().setLineHeight(v),
            ),
            const SizedBox(height: 12),
            Text(
              'Razmak između slova '
              '(${settings.letterSpacing.toStringAsFixed(1)} px)',
            ),
            Slider(
              value: settings.letterSpacing,
              min: 0.0,
              max: 1.5,
              divisions: 3,
              label: '+${settings.letterSpacing.toStringAsFixed(1)}',
              onChanged: (v) =>
                  context.read<AccessibilitySettings>().setLetterSpacing(v),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Podebljan tekst'),
              subtitle: const Text('Olakšava čitanje za slabovidne korisnike'),
              value: settings.boldText,
              onChanged: (v) =>
                  context.read<AccessibilitySettings>().setBoldText(v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Povišeni kontrast'),
              subtitle: const Text('Jače boje za slabovidne korisnike'),
              value: settings.highContrast,
              onChanged: (v) =>
                  context.read<AccessibilitySettings>().toggleHighContrast(v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Veći elementi sučelja'),
              subtitle: const Text('Povećani dodirni ciljevi i razmak'),
              value: settings.largeControls,
              onChanged: (v) =>
                  context.read<AccessibilitySettings>().setLargeControls(v),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zatvori'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showAccessibilityPanel(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const AccessibilityPanel(),
  );
}
