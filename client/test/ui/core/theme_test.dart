import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/ui/core/themes/theme.dart';

/// The accent is white, which makes any surface it fills a *light* one. These
/// pin the "content on the accent inverts" rule, because the failure mode is
/// silent — white text on a white chip still lays out and still passes a
/// `find.text`, it is just invisible.
Widget harness(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: child),
);

/// The colour the chip's label is actually painted with, after the theme's
/// state-dependent colour has been resolved for the chip's current states.
Color? labelColorOf(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color ??
    DefaultTextStyle.of(tester.element(find.text(label))).style.color;

void main() {
  testWidgets('a selected chip inverts its label off the white accent', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const Wrap(
          children: [
            ChoiceChip(label: Text('Critical'), selected: true),
            ChoiceChip(label: Text('Low'), selected: false),
          ],
        ),
      ),
    );

    final selected = labelColorOf(tester, 'Critical');
    final unselected = labelColorOf(tester, 'Low');

    expect(
      selected,
      isNot(unselected),
      reason: 'selected and unselected labels must not paint the same colour',
    );
    expect(
      selected!.computeLuminance(),
      lessThan(AppTheme.colorScheme.primary.computeLuminance()),
      reason: 'the label must be darker than the accent it sits on',
    );
    expect(
      unselected!.computeLuminance(),
      greaterThan(AppTheme.colorScheme.surface.computeLuminance()),
      reason: 'the label must be lighter than the surface it sits on',
    );
  });

  testWidgets('a filled button inverts its label off the white accent', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(FilledButton(onPressed: () {}, child: const Text('Submit'))),
    );

    final color = DefaultTextStyle.of(tester.element(find.text('Submit')))
        .style
        .color;

    expect(
      color!.computeLuminance(),
      lessThan(AppTheme.colorScheme.primary.computeLuminance()),
    );
  });
}
