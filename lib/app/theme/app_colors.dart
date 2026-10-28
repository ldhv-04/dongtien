import 'package:flutter/material.dart';

/// Authoritative Design System Color Tokens for Đồng Tiền.
/// Extracted directly from Untitled-3.png across 7 color families:
/// 1. Primary Jade (Verdant)
/// 2. Slate Neutral (Charcoal)
/// 3. Accent Amber (Sandstone / Marigold / Ember)
/// 4. Accent Ruby
/// 5. Functional Blue
/// 6. Surface (Neutral)
/// 7. Overlay & Scrim
class AppColors {
  AppColors._();

  // ===========================================================================
  // 1. PRIMARY JADE / VERDANT FAMILY (Financial Health, Assets, Safe-to-Spend)
  // ===========================================================================
  static const Color jade14 = Color(0xFF215B44); // Deepest hero text
  static const Color jade11 = Color(0xFF3D785F); // Secondary text / headings
  static const Color jade10 = Color(0xFF4E886F); // Primary fill, FAB, CTA
  static const Color jade01 = Color(0xFFF3F7F5); // Hero card background tint

  // ===========================================================================
  // 2. SLATE NEUTRAL / CHARCOAL FAMILY (Typography, Borders, Inactive Fill)
  // ===========================================================================
  static const Color charcoal16 = Color(0xFF4D4845); // textPrimary, iconPrimary
  static const Color charcoal12 = Color(0xFF65605C); // textSecondary
  static const Color charcoal09 = Color(0xFF928F8B); // textTertiary
  static const Color charcoal08 = Color(0xFFA6A4A0); // iconSecondary
  static const Color charcoal05 =
      Color(0xFFDBDBD8); // textDisabled, iconDisabled
  static const Color charcoal04 =
      Color(0xFFE7E7E4); // borderSecondary (Card border)
  static const Color charcoal03 =
      Color(0xFFEFEFED); // surfaceTertiary, track fill
  static const Color charcoal02 = Color(0xFFF4F4F2); // borderPrimary (Hairline)
  static const Color charcoal01 =
      Color(0xFFF6F6F4); // surfaceSecondary (Scaffold bg)

  // ===========================================================================
  // 3. ACCENT AMBER / SANDSTONE / MARIGOLD / EMBER FAMILY (Warnings, Budgets >= 80%)
  // ===========================================================================
  static const Color amber14 = Color(0xFF823F00); // marigold-14
  static const Color amber11 = Color(0xFFAC5500); // marigold-11 warning text
  static const Color amber07 =
      Color(0xFFFAA800); // marigold-07 warning progress
  static const Color amber05 = Color(0xFFFFC542); // marigold-05
  static const Color amber01 = Color(0xFFFFF5E3); // marigold-01 warning bg tint

  static const Color sandstone14 = Color(0xFF764527);
  static const Color sandstone11 = Color(0xFF976035);
  static const Color sandstone09 = Color(0xFFD59D6F);
  static const Color sandstone08 = Color(0xFFD99650);
  static const Color sandstone07 = Color(0xFFF0AB59);
  static const Color sandstone01 = Color(0xFFFDF6E4);

  static const Color ember14 = Color(0xFF8B3711);
  static const Color ember11 = Color(0xFFB84B17);
  static const Color ember09 = Color(0xFFE86B1C);
  static const Color ember08 = Color(0xFFFD8240);
  static const Color ember01 = Color(0xFFFFF4F0);

  // ===========================================================================
  // 4. ACCENT RUBY FAMILY (Deficit, Expenses, Over-budget > 100%, Danger)
  // ===========================================================================
  static const Color ruby14 = Color(0xFF9A2329); // Deficit / danger text
  static const Color ruby11 = Color(0xFFC9362B); // Expense text
  static const Color ruby10 = Color(0xFFE0462F); // ruby icon
  static const Color ruby09 =
      Color(0xFFF55D3E); // Danger button, overflow progress
  static const Color ruby01 = Color(0xFFFFF4F1); // Deficit hero background tint
  static const Color rubyAccentPrimary = Color(0xFFE55959);

  // ===========================================================================
  // 5. FUNCTIONAL BLUE FAMILY (Transfers, Information, Account Reconciliation)
  // ===========================================================================
  static const Color blue14 = Color(0xFF1565C0); // Transfer text
  static const Color blue11 = Color(0xFF1976D2); // Info icon
  static const Color blue08 = Color(0xFF2196F3); // Transfer indicator
  static const Color blue01 = Color(0xFFE3F2FD); // Transfer chip background

  // ===========================================================================
  // 6. SURFACE FAMILY (Cards, Scaffolds, Dialogs)
  // ===========================================================================
  static const Color neutral01 =
      Color(0xFFFFFFFF); // surfacePrimary (Cards, Sheets)
  static const Color surfacePrimary = neutral01;
  static const Color surfaceSecondary = charcoal01; // Scaffold background
  static const Color surfaceTertiary = charcoal03; // Inactive tracks, dividers

  // ===========================================================================
  // 7. OVERLAY & SCRIM FAMILY (Modals, Dialogs)
  // ===========================================================================
  static const Color surfaceOverlay =
      Color(0x634D4845); // alpha-09 (Modal barrier 39%)
  static const Color scrimLight = Color(0x26000000);

  // ===========================================================================
  // SEMANTIC TOKEN ALIASES (Matching docs/DESIGN_AND_TEST_PLAN.md Section 1.3)
  // ===========================================================================
  static const Color textPrimary = charcoal16;
  static const Color textSecondary = charcoal12;
  static const Color textTertiary = charcoal09;
  static const Color textDisabled = charcoal05;
  static const Color textInverse = neutral01;

  static const Color textAccentVerdantPrimary = jade14;
  static const Color textAccentVerdantSecondary = jade11;
  static const Color textAccentSandstonePrimary = sandstone14;
  static const Color textAccentSandstoneSecondary = sandstone11;
  static const Color textAccentEmberPrimary = ember14;
  static const Color textAccentEmberSecondary = ember11;
  static const Color textAccentRubyPrimary = ruby14;
  static const Color textAccentRubySecondary = ruby11;
  static const Color textAccentMarigoldPrimary = amber14;
  static const Color textAccentMarigoldSecondary = amber11;

  static const Color surfaceAccentVerdantPrimary = jade11;
  static const Color surfaceAccentVerdantSecondary = jade01;
  static const Color surfaceAccentSandstonePrimary = sandstone09;
  static const Color surfaceAccentSandstoneSecondary = sandstone01;
  static const Color surfaceAccentEmberPrimary = ember09;
  static const Color surfaceAccentEmberSecondary = ember01;
  static const Color surfaceAccentRubyPrimary = rubyAccentPrimary;
  static const Color surfaceAccentRubySecondary = ruby01;
  static const Color surfaceAccentMarigoldPrimary = amber05;
  static const Color surfaceAccentMarigoldSecondary = amber01;

  static const Color fillPrimary = neutral01;
  static const Color fillSecondary = charcoal01;
  static const Color fillTertiary = charcoal03;
  static const Color fillAccentVerdantPrimary = jade10;
  static const Color fillAccentVerdantSecondary = jade01;
  static const Color fillAccentSandstonePrimary = sandstone07;
  static const Color fillAccentSandstoneSecondary = sandstone01;
  static const Color fillAccentEmberPrimary = ember08;
  static const Color fillAccentEmberSecondary = ember01;
  static const Color fillAccentRubyPrimary = ruby09;
  static const Color fillAccentRubySecondary = ruby01;
  static const Color fillAccentMarigoldPrimary = amber07;
  static const Color fillAccentMarigoldSecondary = amber01;

  static const Color borderPrimary = charcoal02;
  static const Color borderSecondary = charcoal04;
  static const Color borderInverse = charcoal16;
  static const Color borderAccentVerdant = jade10;
  static const Color borderAccentSandstone = sandstone07;
  static const Color borderAccentEmber = ember08;
  static const Color borderAccentRuby = ruby09;
  static const Color borderAccentMarigold = amber07;

  static const Color iconPrimary = charcoal16;
  static const Color iconSecondary = charcoal08;
  static const Color iconDisabled = charcoal05;
  static const Color iconInverse = neutral01;
  static const Color iconAccentVerdant = jade10;
  static const Color iconAccentSandstone = sandstone08;
  static const Color iconAccentEmber = ember09;
  static const Color iconAccentRuby = ruby10;
  static const Color iconAccentMarigold = Color(0xFFEE8D00);
}
