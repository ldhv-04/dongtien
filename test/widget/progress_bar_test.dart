import 'package:dongtien/app/theme/app_colors.dart';
import 'package:dongtien/core/widgets/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgressBar Widget Tests', () {
    testWidgets('Renders normal state with verdant color when ratio < 0.8',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: ProgressBar(ratio: 0.5),
            ),
          ),
        ),
      ));

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration?;
      expect(decoration?.color, AppColors.fillAccentVerdantPrimary);
    });

    testWidgets(
        'Renders warning state with marigold color when ratio is between 0.8 and 1.0',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: ProgressBar(ratio: 0.85),
            ),
          ),
        ),
      ));

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration?;
      expect(decoration?.color, AppColors.fillAccentMarigoldPrimary);
    });

    testWidgets(
        'Renders exceeded state with ruby color and overflow indicator when ratio > 1.0',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: ProgressBar(ratio: 1.25),
            ),
          ),
        ),
      ));

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration?;
      expect(decoration?.color, AppColors.fillAccentRubyPrimary);

      // Verify overflow indicator
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasOverflowIndicator = containers.any(
        (c) => c.color == AppColors.ruby14,
      );
      expect(hasOverflowIndicator, isTrue);
    });
  });
}
