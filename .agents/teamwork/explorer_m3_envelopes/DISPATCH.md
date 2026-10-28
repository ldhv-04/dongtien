## 2026-10-27T19:42:23Z
You are explorer_m3_envelopes.
Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m3_envelopes
Read:
- c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
- c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_1\PROJECT.md
- c:\Users\coihu12\Documents\App\AGENTS.md
- c:\Users\coihu12\Documents\App\docs\DESIGN_AND_TEST_PLAN.md (Sections 4, 5, 6)
- c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md
- `lib/domain/envelopes/`
- `lib/core/database/daos/envelope_dao.dart`

Investigate and author a detailed implementation blueprint for:
1. Virtual Funds (Quỹ tiền) Screen (Tab 2) in `lib/features/envelopes/`:
   - Summary Header Bar:
     * Tổng tài sản khả dụng (`total_liquid_assets`).
     * Đã phân bổ vào quỹ (`total_envelope_reserves`).
     * Sẵn sàng phân bổ (`available_to_allocate = liquid - reserves - buffer`).
     * Quỹ dự phòng tiền mặt (`minimum_cash_buffer_vnd`).
     * Over-allocation warning banner if `available_to_allocate < 0`.
   - Categorized Envelope Lists:
     * `PROTECTED` (Quỹ bảo vệ / Bắt buộc): emergency fund, rent, bills.
     * `FLEXIBLE` (Quỹ linh hoạt / Tùy chọn): dining out, shopping, discretionary.
   - Envelope Card Component:
     * Name, reserved balance, target amount, target progress bar, negative badge if deficit.
   - Envelope Detail Screen:
     * Current reserved balance, target date, progress bar.
     * Action buttons: Phân bổ (`ALLOCATE`), Rút tiền (`RELEASE`), Chuyển quỹ (`TRANSFER`).
     * Movement History List: chronological log of movements (`ALLOCATE`, `RELEASE`, `TRANSFER`, `SPEND`, `REFUND_RESTORE`, `REVERSAL`).
   - Action Modals:
     * Allocate modal: numeric keypad, enforces `amount <= available_to_allocate`.
     * Release modal: numeric keypad, enforces `amount <= reservedBalance` unless negative confirmed.
     * Transfer modal: selects source and destination (`source != dest`), enforces `amount <= source.reservedBalance`.
     * Create/Edit envelope modal: name, policy selector (`PROTECTED` vs `FLEXIBLE`), target amount, target date, `allow_negative_exception` toggle.
2. Riverpod state management: Providers and Notifiers.
3. Semantics identifiers and widget test plan.

Write your full blueprint report to:
c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m3_envelopes\handoff.md
Notify orchestrator when done.
