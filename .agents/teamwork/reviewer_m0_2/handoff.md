# Handoff Report: Milestone M0 Reviewer (`reviewer_m0_2`)

**Agent**: `reviewer_m0_2`  
**Roles**: reviewer, critic  
**Milestone**: M0 (Design System & Test Plan Review)  
**Parent Conversation ID**: `4b707e3a-5355-44d8-b48d-d32bbd3220b1`  
**Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\reviewer_m0_2`  
**Review Target Deliverables**:
- `c:\Users\coihu12\Documents\App\AGENTS.md`
- `c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md`
- `c:\Users\coihu12\Documents\App\docs\DESIGN_AND_TEST_PLAN.md`
- Reference assets in `c:\Users\coihu12\Documents\App\docs\design_refs\`

---

## Review Summary

**Verdict**: **APPROVE**

Milestone M0 documentation deliverables prepared by `worker_m0_1` strictly conform to the authoritative build specification (`build_spec/dongtien_build_spec.md`), the project scope (`PROJECT.md`), and the local design assets (`docs/design_refs/`). The design system tokens, typography line heights, color hex codes, navigation shell architecture, keypad layout, notification permissions, and all 15 acceptance test scenarios are mathematically exact, fully articulated, and free of placeholders, shortcuts, or integrity violations.

---

## 1. Observation

Direct observations verified across the codebase and visual references:

### 1.1 Design Token Faithfulness
1. **Spacing Tokens (`docs/design_refs/Spacing.png` vs `docs/DESIGN_AND_TEST_PLAN.md:13-54`)**:
   - `Spacing.png` specifies a 16-step scale based on a 4px grid: `sp-0` (0px), `sp-1` (1px), `sp-2` (2px), `sp-3` (4px), `sp-4` (8px), `sp-5` (12px), `sp-6` (16px), `sp-7` (20px), `sp-8` (24px), `sp-9` (32px), `sp-10` (40px), `sp-11` (48px), `sp-12` (64px), `sp-13` (80px), `sp-14` (96px), `sp-15` (128px).
   - In `docs/DESIGN_AND_TEST_PLAN.md` lines 36–53, class `AppSpacing` defines `sp0` through `sp15` with these exact floating-point pixel constants. All 16 tokens match verbatim.
2. **Typography Scale (`docs/design_refs/Untitled-2.png` vs `docs/DESIGN_AND_TEST_PLAN.md:58-122`)**:
   - `Untitled-2.png` defines 7 tiers with Regular and Medium weights:
     - `Large Title`: font-size 32px, line-height 48px, tracking 0px.
     - `Title`: font-size 24px, line-height 36px, tracking 0px.
     - `Headline`: font-size 20px, line-height 30px, tracking 0px.
     - `Body`: font-size 16px, line-height 24px, tracking 0%.
     - `Subheadline`: font-size 14px, line-height 20px, tracking 0%.
     - `Footnote`: font-size 12px, line-height 16px, tracking 0%.
     - `Caption`: font-size 10px, line-height 14px, tracking 0%.
   - In `docs/DESIGN_AND_TEST_PLAN.md` lines 73–121, class `AppTypography` defines these styles with identical `fontSize`, line height ratios (`height: line_height / font_size`), and weights (`w400` for Regular, `w500` for Medium). All 7 tiers match verbatim.
3. **Semantic Color Palette (`docs/design_refs/Untitled-3.png` vs `docs/DESIGN_AND_TEST_PLAN.md:126-200`)**:
   - `Untitled-3.png` details 59 distinct semantic tokens across 7 families:
     - Text: `text-primary` (`#4D4845`), `text-secondary` (`#65605C`), `text-tertiary` (`#928F8B`), `text-disabled` (`#DBDBD8`), `text-inverse` (`#FFFFFF`), `text-accent-verdant-primary` (`#215B44`), `text-accent-verdant-secondary` (`#3D785F`), `text-accent-sandstone-primary` (`#764527`), `text-accent-sandstone-secondary` (`#976035`), `text-accent-ember-primary` (`#8B3711`), `text-accent-ember-secondary` (`#B84B17`), `text-accent-ruby-primary` (`#9A2329`), `text-accent-ruby-secondary` (`#C9362B`), `text-accent-marigold-primary` (`#823F00`), `text-accent-marigold-secondary` (`#AC5500`).
     - Surface: `surface-primary` (`#FFFFFF`), `surface-secondary` (`#F6F6F4`), `surface-tertiary` (`#EFEFED`), `surface-overlay` (`#4D4845 39%` -> `0x634D4845`), `surface-accent-verdant-primary` (`#3D785F`), `surface-accent-verdant-secondary` (`#F3F7F5`), `surface-accent-sandstone-primary` (`#D59D6F`), `surface-accent-sandstone-secondary` (`#FDF6E4`), `surface-accent-ember-primary` (`#E86B1C`), `surface-accent-ember-secondary` (`#FFF4F0`), `surface-accent-ruby-primary` (`#E55959`), `surface-accent-ruby-secondary` (`#FFF4F1`), `surface-accent-marigold-primary` (`#FFC542`), `surface-accent-marigold-secondary` (`#FFF5E3`).
     - Fill: `fill-primary` (`#FFFFFF`), `fill-secondary` (`#F6F6F4`), `fill-tertiary` (`#EFEFED`), `fill-accent-verdant-primary` (`#4E886F`), `fill-accent-verdant-secondary` (`#F3F7F5`), `fill-accent-sandstone-primary` (`#F0AB59`), `fill-accent-sandstone-secondary` (`#FDF6E4`), `fill-accent-ember-primary` (`#FD8240`), `fill-accent-ember-secondary` (`#FFF4F0`), `fill-accent-ruby-primary` (`#F55D3E`), `fill-accent-ruby-secondary` (`#FFF4F1`), `fill-accent-marigold-primary` (`#FAA800`), `fill-accent-marigold-secondary` (`#FFF5E3`).
     - Border: `border-primary` (`#F4F4F2`), `border-secondary` (`#E7E7E4`), `border-inverse` (`#4D4845`), `border-accent-verdant` (`#4E886F`), `border-accent-sandstone` (`#F0AB59`), `border-accent-ember` (`#FD8240`), `border-accent-ruby` (`#F55D3E`), `border-accent-marigold` (`#FAA800`).
     - Icon: `icon-primary` (`#4D4845`), `icon-secondary` (`#A6A4A0`), `icon-disabled` (`#DBDBD8`), `icon-inverse` (`#FFFFFF`), `icon-accent-verdant` (`#4E886F`), `icon-accent-sandstone` (`#D99650`), `icon-accent-ember` (`#E86B1C`), `icon-accent-ruby` (`#E0462F`), `icon-accent-marigold` (`#EE8D00`).
   - In `docs/DESIGN_AND_TEST_PLAN.md` lines 130–199, class `AppColors` defines every single token with identical hex values and alpha calculations (`0x63` for 39%). All 59 tokens match verbatim.

### 1.2 Tabular Numerals Requirement
- `AGENTS.md:35-37` and `AGENTS.md:255-259`: Explicitly mandates `fontFeatures: [FontFeature.tabularFigures()]` on every widget displaying monetary figures (`VndMoney`), percentages, or dates.
- `docs/DESIGN_AND_TEST_PLAN.md:59-60`: Mandates `fontFeatures: [FontFeature.tabularFigures()]` to ensure fixed-width numerical glyphs and eliminate layout jitter during dynamic updates.

### 1.3 Screen Navigation & Custom Numeric Keypad
- **Navigation Shell**:
  - `docs/DESIGN_AND_TEST_PLAN.md:272-306`: Defines the root `MainNavigationShell` with `IndexedStack` hosting the 4 bottom tabs: (0) `Tổng quan` (Dashboard), (1) `Giao dịch` (Transactions), (2) `Quỹ tiền` (Virtual Funds), (3) `Kế hoạch` (Plans).
  - Secondary screens (`Báo cáo`, `Cài đặt & Sao lưu`, `Chi tiết Quỹ`, `Lịch sử chỉnh sửa`) are pushed via standard `Navigator.push`.
  - `AGENTS.md:197`: Enforces `IndexedStack` + standard `Navigator` while strictly banning `go_router`.
- **Custom Numeric Keypad (`docs/design_refs/wallet.png` vs `docs/DESIGN_AND_TEST_PLAN.md:237-270`)**:
  - Layout: 4 rows $\times$ 3 columns (digits 1–9, bottom row: empty, 0, `<` backspace).
  - Touch targets: Minimum 48x48px (`AppSpacing.sp11`), recommended 64x56px.
  - Formatted display: Dynamic real-time VND formatting (e.g., `1.250.000 ₫`).
  - Segmented selector: `Chi tiêu` (Expense), `Thu nhập` (Income), `Chuyển khoản` (Transfer), `Trả thẻ` (Card Payment), `Hoàn tiền` (Refund), with progressive form disclosures.
  - CTA Button: Ember pill button (`#FD8240`), label "Lưu giao dịch", with unique client `idempotency_key`.

### 1.4 Notification Compliance (Android 12–15+)
- `docs/DESIGN_AND_TEST_PLAN.md:395-424`:
  - Declares only `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` and `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>`.
  - Strictly prohibits `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM`.
  - Specifies scheduling mode: `AndroidScheduleMode.inexactAllowWhileIdle`.
  - Defines 3 channels: `dongtien_daily_summary`, `dongtien_obligations`, `dongtien_budget_alerts`.
  - Specifies graceful degradation on permission denial (Scenario 15).

### 1.5 Test Matrices (The 15 Mandatory Scenarios)
- `docs/DESIGN_AND_TEST_PLAN.md:426-687`:
  - **Scenario 1**: Opening Asset `10.000.000 ₫` $\to$ Asset `10M`, Liquid `10M`, Operating Income `0 ₫`, Net Expense `0 ₫`, Safe-to-Spend `10M`.
  - **Scenario 2**: Salary `20.000.000 ₫` $\to$ Bank `20M`, Liquid `30M`, Income `20M`, Net Expense `0 ₫`, Saving Rate `1.0` (100%), Safe-to-Spend `30M`.
  - **Scenario 3**: Cash Expense `100.000 ₫` $\to$ Cash `9.9M`, Liquid `29.9M`, Net Expense `100k`, Saving Rate `0.995` (99.5%), Safe-to-Spend `29.9M`.
  - **Scenario 4**: Internal Transfer `2.000.000 ₫` $\to$ Cash `11.9M`, Bank `18M`, Liquid `29.9M` (unchanged), Income & Expense unchanged, Safe-to-Spend `29.9M` (unchanged).
  - **Scenario 5**: Virtual Fund Allocation `1.000.000 ₫` to Protected Fund $\to$ Liquid `29.9M` (unchanged), Reserve `1.000.000 ₫`, Safe-to-Spend `28.9M` (decreased by 1M).
  - **Scenario 6**: Credit Card Purchase `500.000 ₫` $\to$ Card Debt `500k`, Liquid `29.9M` (unchanged), Net Expense `600k`, Net Worth `29.4M`.
  - **Scenario 7**: Credit Card Payment `500.000 ₫` $\to$ Debt cleared `0 ₫`, Bank `17.5M`, Liquid `29.4M`, Net Expense `600k` (strictly unchanged!).
  - **Scenario 8**: Refund `50.000 ₫` $\to$ Bank `17.55M`, Liquid `29.45M`, Net Expense `550k`, linked envelope restored `50k`.
  - **Scenario 9**: Void & Edit $\to$ Reversals balance `SUM(debit) == SUM(credit)`, accounts reconcile, default UI filters `WHERE status = 'POSTED' AND tx_type != 'REVERSAL'`.
  - **Scenario 10**: Duplicate Submission Guard $\to$ Duplicate `idempotency_key = "idemp-001"` produces exactly 1 transaction in DB.
  - **Scenario 11**: Scheduled Bill `1.500.000 ₫` & Payment $\to$ Chronologically offsets 1M protected reserve; Safe-to-Spend before payment is `8.5M`; after payment liquid is `8.5M` and Safe-to-Spend remains `8.5M` (zero double-counting proved).
  - **Scenario 12**: Negative Safe-to-Spend $\to$ Liquid 2M, Protected 1.5M, Unfunded 1M, Buffer 1M $\to$ Exact shortfall `-1.500.000 ₫` (not clamped to 0), daily rate `0 ₫/ngày`, rendered in red (`textAccentRubyPrimary`).
  - **Scenario 13**: Encrypted Backup Round-Trip $\to$ Outer JSON `magic: "DONGTIEN_ENC_V1"`, PBKDF2 120k iterations, AES-256-GCM, DB wipe and atomic restore matching pre-wipe state bit-for-bit.
  - **Scenario 14**: Tampered Backup / Wrong Password $\to$ 1 bit flip in ciphertext/mac or wrong password throws `SecretBoxAuthenticationError` inside `Isolate.run`; SQLite database untouched.
  - **Scenario 15**: Permission Denied & Month-End Recurrence $\to$ App fully functional without notification permission; monthly bill anchored on day `31` schedules on `Feb 28/29` and returns to `Mar 31` without anchor loss.

---

## 2. Logic Chain

1. **Token Accuracy from Ground Truth**:
   Visual assets in `docs/design_refs/` (`Spacing.png`, `Untitled-2.png`, `Untitled-3.png`, `wallet.png`) represent the authoritative design intent. Comparing each token in `docs/DESIGN_AND_TEST_PLAN.md` with the corresponding image confirmed that the author faithfully transcribed all 16 spacing values, all 7 typography scales, and all 59 semantic color codes with zero omissions or arbitrary alterations.
2. **Typography Consistency & Layout Stability**:
   Financial applications on Android experience layout jitter when proportional numbers dynamically update. Mandating `fontFeatures: [FontFeature.tabularFigures()]` across all amount, percentage, and date text widgets eliminates glyph width variance.
3. **Architecture Contract Enforceability**:
   The `IndexedStack` root shell preserves the state of all 4 tabs during frequent tab switching, avoiding reconstructive widget churn or query reload overhead. Specifying standard `Navigator.push` for secondary screens complies with Android back gesture expectations while enforcing the strict ban on `go_router`.
4. **Platform Compliance & Store Approval**:
   Using `AndroidScheduleMode.inexactAllowWhileIdle` and avoiding `SCHEDULE_EXACT_ALARM` protects the application from Google Play store rejections under Android 13–15 policies.
5. **Scenario Testability**:
   Every acceptance scenario defines explicit input state, database postings, and mathematical assertion outcomes. This makes downstream test authoring in Phase 2 and Phase 5 straightforward and deterministic.

---

## 3. Adversarial Challenges & Stress Tests

### Challenge 1: Custom Keypad vs Android Soft Keyboard Collision
- **Assumption Challenged**: Tapping on the transaction amount display will not trigger Android's native soft keyboard (IME).
- **Attack Scenario**: If the amount display is built using an active `TextField` without disabling the soft keyboard, Android will automatically spawn the system keyboard, covering the custom numeric keypad and distorting the modal layout.
- **Blast Radius**: Severe UI breakage during quick transaction entry.
- **Mitigation Requirement for Phase 3**: Downstream implementers must make the amount display read-only (`readOnly: true`, `showCursor: false`, or use a custom `Text` widget) so only taps on the custom keypad buttons mutate the entered VND value.

### Challenge 2: Numeric Keypad Input Boundary & Overflow Protection
- **Assumption Challenged**: Keypad input safely handles leading zeros, backspace on zero, and 64-bit VND overflow.
- **Attack Scenario**:
  1. User presses `0` when amount is `0 ₫`: If not guarded, display becomes `00 ₫`.
  2. User presses `<` (backspace) on `5 ₫`: If not guarded, value becomes empty string `""` or throws parsing exception.
  3. User presses 17 digits ($> 9 \times 10^{15}$): Integer overflow occurs.
- **Mitigation**:
  - Keypad state machine must ignore additional `0` presses when current value is `0`.
  - Backspace on single digit must reset value to `0`, formatting as `0 ₫`.
  - Input engine must clamp or disallow digit entry when `current_value * 10 + digit > max_Safe_VND` (`9_000_000_000_000_000`).

### Challenge 3: Rapid Double-Tap Submission on Low-End Devices
- **Assumption Challenged**: Double-tapping the "Lưu giao dịch" button will not generate duplicate transactions.
- **Stress Test**: A user rapidly taps the submit button twice within 50ms.
- **Mitigation**: Verified that `docs/DESIGN_AND_TEST_PLAN.md` §2.2 and `AGENTS.md` §5.3 attach a unique client `idempotency_key` per Quick-Add session and enforce a database unique constraint on `idempotency_key`, with Riverpod controller disabling the CTA upon first click.

### Integrity Violation Check
- **Hardcoded test results in source code**: None detected.
- **Dummy or facade implementations**: None detected.
- **Shortcuts bypassing requirements**: None detected.
- **Cheating or self-certification**: None detected.

---

## 4. Caveats

1. **Pre-Code Milestone**: Milestone M0 is strictly dedicated to lean architecture, specifications, and test plan authoring. No application source code (`lib/`) or test executable (`test/`) was authored in this phase.
2. **Device Timezone Dependency**: Inexact alarm delivery may drift by $\pm 10$ to 15 minutes due to Android battery optimization batching under Doze mode. This is documented and standard for personal finance reminders.
3. **No other caveats.**

---

## 5. Conclusion

Milestone M0 deliverables are **APPROVED**.
The documentation provides an exhaustive, mathematically verified, and aesthetically faithful foundation for Đồng Tiền. The project is completely unblocked and ready for Phase 1 scaffolding and Drift database implementation.

---

## 6. Verification Method

To independently verify these findings:

1. **Compare Design Tokens Against Reference Images**:
   - Inspect `docs/design_refs/Spacing.png` vs `docs/DESIGN_AND_TEST_PLAN.md:36-53`.
   - Inspect `docs/design_refs/Untitled-2.png` vs `docs/DESIGN_AND_TEST_PLAN.md:73-121`.
   - Inspect `docs/design_refs/Untitled-3.png` vs `docs/DESIGN_AND_TEST_PLAN.md:130-199`.
   - Inspect `docs/design_refs/wallet.png` vs `docs/DESIGN_AND_TEST_PLAN.md:237-270`.
2. **Verify Tabular Numerals Mandate**:
   - Check `AGENTS.md:35-37`, `AGENTS.md:255-259`, and `docs/DESIGN_AND_TEST_PLAN.md:59-60`.
3. **Verify Notification Permissions & Inexact Scheduling**:
   - Check `docs/DESIGN_AND_TEST_PLAN.md:397-408`.
4. **Verify Test Matrices**:
   - Inspect `docs/DESIGN_AND_TEST_PLAN.md:426-687` for Scenarios 1 through 15.
