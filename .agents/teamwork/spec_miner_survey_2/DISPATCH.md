## 2026-10-27T10:07:13Z
You are spec_miner_survey_2, working as UI/UX & Security Spec Miner.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_survey_2
Read the authoritative user request at: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
Read the build specification at: c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md
Inspect the visual design references in: c:\Users\coihu12\Documents\App\docs\design_refs\
(Spacing.png, Untitled.png, Untitled-1.png, Untitled-2.png, Untitled-3.png, budget.png, invest.png, savings.png, wallet.png).

Your task is to thoroughly analyze and extract the complete specifications for UI/UX, Design System, Local Notifications, and Security/Backup of DongTien:
1. Design System & Tokens:
   - Colors, typography (tabular numerals, vi_VN locale), spacing, card radius, elevations, icons, and visual layout hierarchy extracted from the 9 design reference images.
2. Navigation & Architecture:
   - 4 Bottom Navigation tabs (Tổng quan, Giao dịch, Quỹ tiền, Kế hoạch) using IndexedStack + standard Navigator.
   - Secondary screens (Báo cáo, Cài đặt & Sao lưu) accessed via AppBar actions.
3. Detailed Screen Requirements & Interactive Components:
   - Tổng quan (Dashboard): Safe-to-Spend hero card, breakdown modal, spending vs budget, upcoming obligations & next income, fund progress, recent 5 transactions, Quick-Add FAB.
   - Giao dịch (Transactions & Accounts): Day-grouped list with daily net total, search bar, filter chips (type, account, category, envelope, date range), Account management drawer/header, Audit History bottom sheet ("Lịch sử chỉnh sửa").
   - Quick-Add Transaction UX: Custom numeric keypad / focused amount, segmented selector (Chi tiêu, Thu nhập, Chuyển khoản, Trả thẻ, Hoàn tiền), category grid, account chips, optional envelope & note.
   - Quỹ tiền (Virtual Funds): Liquid assets, Reserved, Available-to-allocate summary; Protected vs Flexible envelopes; quick Allocate/Transfer/Release actions; Fund detail with movement history.
   - Kế hoạch (Plans): Segmented view for (a) Category Budgets, (b) Savings Goals with feasibility advisor, (c) Scheduled Items & 30/60/90-day Cash-Flow Forecast.
   - Báo cáo (Reports): Income, Gross Expense, Refunds, Net Expense, Transfers, Saving Rate, Net Worth.
   - Cài đặt & Sao lưu (Settings): Minimum cash buffer, period boundary day, notification toggles, CSV export, Encrypted Backup/Restore, Sample data generator, Reset data.
   - Accessibility / Testing: Semantics(identifier: ...) on all primary buttons, inputs, and summary cards.
4. Compliant Local Notifications (Android 12-15+):
   - Declare only POST_NOTIFICATIONS and RECEIVE_BOOT_COMPLETED.
   - Scheduling mode: AndroidScheduleMode.inexactAllowWhileIdle (NO exact alarms).
   - Triggers: Daily summary, upcoming bill/goal reminders, 80%/100% budget threshold alerts.
   - Graceful degradation if permission denied (Scenario 15).
5. Android Hardening & Encrypted Backup/Restore:
   - android:allowBackup="false" in AndroidManifest.xml and res/xml/data_extraction_rules.xml.
   - Off-main-thread execution using Isolate.run.
   - Outer JSON wrapper with "magic": "DONGTIEN_ENC_V1", PBKDF2-HMAC-SHA256 (120,000 iterations, 16-byte random salt), AES-256-GCM (12-byte random nonce, 16-byte GCM tag).
   - 25 MB max size check, validation of structural invariants in memory before touching DB.
   - User confirmation dialog with timestamp and record counts.
   - Atomic restore inside single db.transaction(). Safe rejection of tampered files or wrong password (Scenario 13 & 14).

Maintain progress.md in your working directory with timestamps.
When complete, write your comprehensive specification report to:
c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_survey_2\handoff.md
And send a completion message back with summary and handoff path.
