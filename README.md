# Đồng Tiền (`vn.dongtien`)

**Đồng Tiền** là ứng dụng quản lý tài chính cá nhân **100% Ngoại tuyến (Offline-First)** dành cho Android, được thiết kế chuyên biệt cho tiền tệ **Việt Nam Đồng (`VND` - số nguyên 64-bit)** và chuẩn локаlization `vi_VN`.

---

## 1. Kiến trúc & Bất biến Hệ thống (Architectural Invariants)

1. **100% Offline-First & Bảo mật Tuyệt đối**:
   - Không máy chủ từ xa, không tài khoản đám mây, không thu thập dữ liệu (telemetry/analytics), không quảng cáo.
   - Đóng cứng Android Sandbox (`android:allowBackup="false"`, `res/xml/data_extraction_rules.xml`).
   - Sao lưu & Khôi phục ngoại tuyến được mã hóa xác thực bằng **PBKDF2-HMAC-SHA256 (`120.000` vòng)** và **AES-256-GCM** (`DONGTIEN_ENC_V1`) chạy hoàn toàn trên `Isolate.run`.
2. **Toán học Tiền tệ Số nguyên 64-bit (`VndMoney`)**:
   - Tuyệt đối không sử dụng `double` hay `float` cho tiền tệ.
   - Mọi số tiền được lưu trữ và tính toán bằng số nguyên 64-bit (`int` / `VndMoney`) với giới hạn an toàn `maxSafeVnd = 9.000.000.000.000.000 ₫`.
   - Định dạng `vi_VN` chuẩn (`1.250.000 ₫`) đi kèm `FontFeature.tabularFigures()` trên mọi thành phần giao diện hiển thị số.
3. **Sổ cái Kép Bất biến (Double-Entry General Ledger) & Tách biệt Quỹ tiền Ảo (Virtual Funds)**:
   - Mọi giao dịch sổ cái (`journal_transactions` & `journal_postings`) thực thi nguyên tử trong `db.transaction()` và thỏa mãn bất biến:
     $$\sum \text{debit\_vnd} == \sum \text{credit\_vnd}$$
   - Các thao tác phân bổ nội bộ giữa các Quỹ tiền ảo (`ALLOCATE`, `RELEASE`, `TRANSFER`) **không bao giờ** sinh bút toán sổ cái và không làm thay đổi số dư tài sản thanh khoản hay báo cáo thu/chi.
   - Xóa (`VOIDED`) hoặc sửa (`SUPERSEDED`) giao dịch luôn bảo toàn lịch sử kiểm toán thông qua giao dịch đảo chiều (`REVERSAL`).
4. **Công thức Safe-to-Spend Không Tính Trùng (Zero Double-Counting)**:
   $$\text{Safe-to-Spend} = \text{Liquid Assets} - \text{Protected Reserves} - \text{Unfunded Committed Outflows} - \text{Minimum Cash Buffer}$$

---

## 2. Cấu trúc Thư mục (Clean Architecture)

- `lib/app/`: Khởi tạo `MaterialApp` (`vi_VN`), khung điều hướng 4 tab (`IndexedStack`), và hệ thống Design Tokens (`AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`).
- `lib/core/`:
  - `money/`: `VndMoney` và `VndFormatter`.
  - `database/`: Cơ sở dữ liệu SQLite/Drift 9 bảng (`app_database.dart`), `LedgerDao`, `EnvelopeDao` với `PRAGMA foreign_keys = ON`.
  - `security/`: `EncryptedBackupService` & `BackupPayloadModels` (`PBKDF2-HMAC-SHA256` + `AES-256-GCM`).
  - `notifications/`: `NotificationScheduler` tuân thủ Android 12–15+ (`AndroidScheduleMode.inexactAllowWhileIdle`, không yêu cầu quyền exact alarm).
  - `widgets/`: `CustomKeypad` và `ProgressBar`.
- `lib/domain/`: Các bộ máy miền thuần Dart (Zero Flutter/Drift imports): `ledger/`, `envelopes/`, `budgeting/`, `forecasting/`.
- `lib/features/`: 6 phân hệ tính năng dùng Riverpod (`dashboard`, `transactions`, `accounts`, `envelopes`, `plans`, `reports_settings`).
- `docs/`:
  - `docs/ARCHITECTURE_AND_RULES.md`: Kiến trúc chi tiết, ma trận hạch toán, công thức toán học và ADRs.
  - `docs/DESIGN_AND_TEST_PLAN.md`: Đặc tả Design Tokens, sơ đồ màn hình, `Semantics` IDs và ma trận 15 kịch bản nghiệm thu.

---

## 3. Hướng dẫn Kiểm tra & Xây dựng (Verification & Build Gates)

```bash
# 1. Kiểm tra định dạng mã nguồn
dart format --output=none --set-exit-if-changed .

# 2. Phân tích tĩnh (0 lỗi, 0 cảnh báo, 0 lint)
flutter analyze

# 3. Chạy toàn bộ bộ kiểm thử tự động (Unit, Database, Widget & 15 kịch bản nghiệm thu)
flutter test --coverage

# 4. Xây dựng gói cài đặt Android Debug APK
flutter build apk --debug
```
