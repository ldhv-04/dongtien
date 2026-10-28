import 'package:dongtien/core/widgets/custom_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder bySemanticsId(String id) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.identifier == id,
    );

void main() {
  group('CustomKeypad Widget Tests', () {
    testWidgets('Renders all digits, backspace, and done buttons',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomKeypad(
            onDigitPressed: (_) {},
            onBackspacePressed: () {},
            onDonePressed: () {},
          ),
        ),
      ));

      for (int i = 0; i <= 9; i++) {
        expect(bySemanticsId('keypad_btn_$i'), findsOneWidget);
        expect(find.text('$i'), findsOneWidget);
      }
      expect(bySemanticsId('keypad_btn_backspace'), findsOneWidget);
      expect(bySemanticsId('keypad_btn_done'), findsOneWidget);
      expect(find.text('Xong'), findsOneWidget);
    });

    testWidgets(
        'Tapping digits, backspace, and done triggers appropriate callbacks',
        (tester) async {
      final List<int> pressedDigits = [];
      bool backspaceCalled = false;
      bool doneCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomKeypad(
            onDigitPressed: (digit) => pressedDigits.add(digit),
            onBackspacePressed: () => backspaceCalled = true,
            onDonePressed: () => doneCalled = true,
          ),
        ),
      ));

      await tester.tap(bySemanticsId('keypad_btn_1'));
      await tester.tap(bySemanticsId('keypad_btn_2'));
      await tester.tap(bySemanticsId('keypad_btn_5'));
      await tester.tap(bySemanticsId('keypad_btn_0'));
      await tester.tap(bySemanticsId('keypad_btn_backspace'));
      await tester.tap(bySemanticsId('keypad_btn_done'));

      expect(pressedDigits, equals([1, 2, 5, 0]));
      expect(backspaceCalled, isTrue);
      expect(doneCalled, isTrue);
    });

    testWidgets('Touch target size adheres to minimum >= 48px height and width',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomKeypad(
            onDigitPressed: (_) {},
            onBackspacePressed: () {},
            onDonePressed: () {},
          ),
        ),
      ));

      final buttonFinder = bySemanticsId('keypad_btn_5');
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
      expect(size.width, greaterThanOrEqualTo(48.0));
    });
  });
}
