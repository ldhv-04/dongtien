## 2026-10-27T18:32:05Z
You are worker_m1_2, working as VndFormatter Bugfix & Verification Engineer.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m1_2

Read the authoritative user request at: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
Read the challenger bug report at: c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m1_1\handoff.md
Read the target implementation at: c:\Users\coihu12\Documents\App\lib\core\money\vnd_formatter.dart
Read the adversarial test harness at: c:\Users\coihu12\Documents\App\test\unit\vnd_money_adversarial_test.dart

Exclusive Write Ownership:
- c:\Users\coihu12\Documents\App\lib\core\money\vnd_formatter.dart
- c:\Users\coihu12\Documents\App\test\unit\vnd_money_test.dart
- c:\Users\coihu12\Documents\App\test\unit\vnd_money_adversarial_test.dart

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your Tasks:
1. Fix BUG-M1-01 (Multi-sign parsing bug):
   In `lib/core/money/vnd_formatter.dart` inside `tryParse`:
   Immediately after removing the leading sign (`-` or `+`), check:
   ```dart
   if (sanitized.contains('-') || sanitized.contains('+')) {
     return null;
   }
   ```
   This prevents consecutive signs (`--1000`, `++1000`, `+-1000`, `- - 1000`) from being parsed as valid integers.

2. Fix BUG-M1-02 (Docstring exception contract):
   In `lib/core/money/vnd_formatter.dart` inside `parse`:
   Detect numerical overflow specifically so `VndOverflowException` is thrown when numbers exceed `maxSafeVnd` / `minSafeVnd`, matching the public docstring contract:
   ```dart
   static int parse(String input) {
     final int? result = tryParse(input);
     if (result != null) return result;

     // Check if the parse failure was specifically due to overflow
     String sanitized = input.trim();
     if (sanitized.startsWith('-') || sanitized.startsWith('+')) {
       sanitized = sanitized.substring(1).trim();
     }
     sanitized = sanitized
         .replaceAll('₫', '')
         .replaceAll('VND', '')
         .replaceAll('vnd', '')
         .replaceAll('.', '')
         .replaceAll(',', '')
         .replaceAll(' ', '')
         .replaceAll('\u00A0', '');
     final int? rawInt = int.tryParse(sanitized);
     if (rawInt != null && (rawInt > VndMoney.maxSafeVnd || -rawInt < VndMoney.minSafeVnd)) {
       throw VndOverflowException(
         'VND amount exceeds max safe limit (±${VndMoney.maxSafeVnd} ₫)',
       );
     }
     throw FormatException('Cannot parse VND amount from: "$input"');
   }
   ```

3. Verification:
   - Run `flutter test test/unit/vnd_money_adversarial_test.dart` -> verify all 28 tests pass!
   - Run `flutter test test/unit/vnd_money_test.dart` -> verify all 30 tests pass!
   - Run `flutter test test/database/app_database_test.dart` -> verify all 14 tests pass!
   - Run `flutter analyze` -> verify 0 issues!
   - Run `dart format --output=none --set-exit-if-changed .` -> verify 0 unformatted files!

Maintain `progress.md` in your working directory.
When complete, write your handoff report to `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m1_2\handoff.md` and send a message back with your report path.
