import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parc_sur_mobile/core/theme/parcsur_theme.dart';
import 'package:parc_sur_mobile/core/widgets/parc_bottom_sheet.dart';

void main() {
  testWidgets('bottom sheet shows title, subtitle, body and stacked actions; Annuler closes it', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final semantics = tester.ensureSemantics();
    var saved = false;
    await tester.pumpWidget(MaterialApp(
      theme: buildParcSurTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showParcBottomSheet<void>(
              context: context,
              title: 'Modifier Koffi Ouattara',
              subtitle: 'Les champs défilent ; les actions restent visibles.',
              primaryLabel: 'Enregistrer',
              onPrimary: () => saved = true,
              child: const Text('Champs'),
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Modifier Koffi Ouattara'), findsOneWidget);
    expect(find.text('Les champs défilent ; les actions restent visibles.'), findsOneWidget);
    expect(find.text('Champs'), findsOneWidget);
    expect(find.bySemanticsLabel('Fermer'), findsOneWidget);
    // Primary action is stacked above "Annuler" (column-reverse in the prototype).
    expect(tester.getTopLeft(find.text('Enregistrer')).dy, lessThan(tester.getTopLeft(find.text('Annuler')).dy));

    await tester.tap(find.text('Enregistrer'));
    expect(saved, isTrue);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier Koffi Ouattara'), findsNothing);
    semantics.dispose();
  });
}
