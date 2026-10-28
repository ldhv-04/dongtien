import 'package:flutter/widgets.dart';

/// 16-step Spacing Scale matching Spacing.png (sp0 = 0dp to sp15 = 128dp).
class AppSpacing {
  AppSpacing._();

  static const double sp0 = 0.0;
  static const double sp1 = 1.0;
  static const double sp2 = 2.0; // spacing2 = 2dp
  static const double sp3 = 4.0; // spacing4 = 4dp
  static const double sp4 = 8.0; // spacing8 = 8dp
  static const double sp5 = 12.0; // spacing12 = 12dp
  static const double sp6 = 16.0; // spacing16 = 16dp
  static const double sp7 = 20.0; // spacing20 = 20dp
  static const double sp8 = 24.0; // spacing24 = 24dp
  static const double sp9 = 32.0; // spacing32 = 32dp
  static const double sp10 = 40.0; // spacing40 = 40dp
  static const double sp11 = 48.0; // spacing48 = 48dp (Min touch target)
  static const double sp12 = 64.0; // spacing64 = 64dp
  static const double sp13 = 80.0; // spacing80 = 80dp (Bottom bar clearance)
  static const double sp14 = 96.0; // spacing96 = 96dp
  static const double sp15 = 128.0; // spacing128 = 128dp

  // Explicit aliases for spacing2 through spacing64
  static const double spacing2 = sp2;
  static const double spacing4 = sp3;
  static const double spacing8 = sp4;
  static const double spacing12 = sp5;
  static const double spacing16 = sp6;
  static const double spacing20 = sp7;
  static const double spacing24 = sp8;
  static const double spacing32 = sp9;
  static const double spacing40 = sp10;
  static const double spacing48 = sp11;
  static const double spacing64 = sp12;

  // Layout Padding Helpers
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(horizontal: sp6);
  static const EdgeInsets paddingCard = EdgeInsets.all(sp6);
  static const EdgeInsets paddingHero = EdgeInsets.all(sp7);
  static const EdgeInsets paddingModal = EdgeInsets.all(sp8);

  // Vertical Gaps
  static const SizedBox gapH4 = SizedBox(height: sp3);
  static const SizedBox gapH8 = SizedBox(height: sp4);
  static const SizedBox gapH12 = SizedBox(height: sp5);
  static const SizedBox gapH16 = SizedBox(height: sp6);
  static const SizedBox gapH20 = SizedBox(height: sp7);
  static const SizedBox gapH24 = SizedBox(height: sp8);
  static const SizedBox gapH32 = SizedBox(height: sp9);

  // Horizontal Gaps
  static const SizedBox gapW4 = SizedBox(width: sp3);
  static const SizedBox gapW8 = SizedBox(width: sp4);
  static const SizedBox gapW12 = SizedBox(width: sp5);
  static const SizedBox gapW16 = SizedBox(width: sp6);
  static const SizedBox gapW24 = SizedBox(width: sp8);
}
