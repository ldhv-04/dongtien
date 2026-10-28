# Handoff Report — Requirement R2: On-Screen Notification Delivery & Verification

**From**: `explorer_survey_2`  
**To**: `orchestrator_2` / Implementer  
**Timestamp**: 2026-10-28T00:53:00Z  
**Type**: Hard Handoff (Investigation & Survey Complete)

---

## 1. Observation

1. **`lib/core/notifications/notification_scheduler.dart`**:
   - Dòng 2–3:
     ```dart
     import 'package:timezone/data/latest_all.dart' as tz_data;
     import 'package:timezone/timezone.dart' as tz;
     ```
     Hoàn toàn không có import hay gọi `flutter_timezone`.
   - Dòng 27–41 (`initialize`):
     ```dart
     Future<bool> initialize() async {
       if (_initialized) return _permissionGranted;
       try {
         tz_data.initializeTimeZones();
         const androidSettings =
             AndroidInitializationSettings('@mipmap/ic_launcher');
         const initSettings = InitializationSettings(android: androidSettings);
         await _plugin.initialize(initSettings);
         _initialized = true;
       } catch (_) {
         // Graceful degradation on desktop/test hosts or when permission denied
         _initialized = false;
       }
       return _permissionGranted;
     }
     ```
     `tz.setLocalLocation` không hề được gọi, do đó `tz.local` luôn là UTC.
     `_plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission()` không hề được gọi.
   - Không có provider Riverpod (`notificationSchedulerProvider`).
   - Không có hàm `showTestNotification()`.
   - Không có hàm `cancelAll()`.
   - Không có hàm `reconcileFromDatabase(AppDatabase db)`.
   - Không có hàm `checkCategoryBudgetAlert({required AppDatabase db, required int categoryId})`.
2. **`android/app/src/main/AndroidManifest.xml`**:
   - Dòng 3–4:
     ```xml
     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
     <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
     ```
     Cấu hình quyền Android đã chính xác và tuân thủ Google Play (không có exact alarm).
3. **`pubspec.yaml`**:
   - Dòng 27–29:
     ```yaml
     flutter_local_notifications: ^17.2.3
     timezone: ^0.9.4
     flutter_timezone: ^3.0.1
     ```
     Đầy đủ thư viện đã được cài đặt trong `pubspec.lock`.
4. **`lib/features/reports_settings/presentation/settings_screen.dart`**:
   - Dòng 21: `final NotificationScheduler _scheduler = NotificationScheduler();` (thực thể cục bộ).
   - Dòng 228–242: Switch toggle chỉ gọi `_scheduler.initialize()`, không gọi lập lịch hay hủy.
   - Chưa có nút "Gửi thông báo kiểm tra ngay" với Semantics `btn_test_notification`.
5. **`lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`**:
   - Dòng 178–188: `updateNotificationsEnabled` chỉ ghi vào SQLite mà không tương tác với scheduler.
6. **`lib/features/plans/presentation/providers/plans_providers.dart`**:
   - Dòng 261–295 (`createScheduledItem`) và dòng 299–466 (`markScheduledItemPaid`) không gọi lập lịch lại thông báo khi tạo hoặc thanh toán hóa đơn.
7. **`lib/features/transactions/presentation/controllers/transaction_controller.dart`**:
   - Dòng 13–37 (`postTransaction`) và dòng 54–76 (`editTransaction`) không kiểm tra ngân sách danh mục chi phí sau khi ghi sổ.
8. **Bộ kiểm thử hiện tại**:
   - Lệnh: `flutter test` đã thực thi và pass 100% (275 tests passed).
   - Chưa có file `test/unit/notification_scheduler_test.dart`.

---

## 2. Logic Chain

1. **Từ Observation 1 và 3**: `flutter_timezone` đã có trong project nhưng không được gọi trong `NotificationScheduler.initialize()`. Khi `tz.setLocalLocation` bị bỏ qua, `tz.local` giữ giá trị UTC. Khi lập lịch nhắc nhở 20:00 (Observation 1 dòng 68–75: `tz.TZDateTime(tz.local, ... settings.dailyReminderHour ...)`), thông báo bị gửi sai lệch 7 tiếng so với múi giờ Việt Nam. Do đó, việc gọi `FlutterTimezone.getLocalTimezone()` kèm fallback `Asia/Ho_Chi_Minh` là điều kiện tiên quyết để sửa lỗi lệch giờ.
2. **Từ Observation 1 và 2**: `AndroidManifest.xml` đã khai báo `POST_NOTIFICATIONS` nhưng trên Android 13/14+ (API 33+), quyền này bắt buộc phải được người dùng cấp thông qua runtime dialog. Vì `NotificationScheduler` chưa gọi `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`, hệ điều hành không bao giờ hiển thị prompt cấp quyền và các thông báo đẩy trên thanh trạng thái/màn hình khóa không thể hiển thị trên thiết bị thật.
3. **Từ Observation 1, 4, 5, 6, 7**: `NotificationScheduler` hiện tại là một lớp cô lập. Các controller xử lý nghiệp vụ tài chính (`TransactionController`, `PlansController`, `ReportsSettingsController`) không thể tương tác với `NotificationScheduler` do thiếu `notificationSchedulerProvider` dùng chung.
4. **Từ Logic step 3**: Bằng cách khai báo `final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) => NotificationScheduler());` và bổ sung các hàm tiện ích `reconcileFromDatabase` và `checkCategoryBudgetAlert` vào `NotificationScheduler`, các controller có thể dễ dàng kích hoạt tự động lập lịch và cảnh báo ngân sách sau mỗi thao tác cơ sở dữ liệu mà không làm rò rỉ mã UI hay vi phạm Clean Architecture.
5. **Từ Observation 4**: Nút "Gửi thông báo kiểm tra ngay" với `Semantics(identifier: 'btn_test_notification')` cho phép người dùng và kiểm thử tự động kiểm tra trực tiếp khả năng bắn thông báo heads-up banner ưu tiên cao (`Importance.max`, `Priority.max`) mà không cần chờ đến giờ cố định.

---

## 3. Caveats

1. **Headless Unit Test Runner**: Trên môi trường headless test (Windows/Linux VM), platform channel của `flutter_timezone` và `flutter_local_notifications` không có native implementation. Code trong `NotificationScheduler` bắt buộc phải có khối `try/catch` bọc quanh các lệnh gọi channel để fallback mượt mà (fallback về `Asia/Ho_Chi_Minh` và giữ `_permissionGranted`).
2. **Acceptance Scenario 15**: Test hiện hữu `test/database/acceptance_scenarios_1_to_15_test.dart` kiểm tra tính năng "Graceful Degradation khi bị từ chối quyền". Khi sửa code, phải đảm bảo `initialPermissionGranted: false` hoặc `setPermissionGranted(false)` vẫn chặn thông báo và không ném ngoại lệ làm hỏng kịch bản 15.

---

## 4. Conclusion

Khảo sát hoàn tất 100%. Toàn bộ 5 nội dung của Yêu cầu R2 đã được định vị chính xác vị trí tập tin, số dòng, nguyên nhân gốc rễ và giải pháp:
1. `NotificationScheduler`: Khởi tạo múi giờ qua `flutter_timezone` (fallback `Asia/Ho_Chi_Minh`), xin quyền `POST_NOTIFICATIONS` qua `AndroidFlutterLocalNotificationsPlugin`, bổ sung `showTestNotification()`, `cancelAll()`, `reconcileFromDatabase()`, và `checkCategoryBudgetAlert()`.
2. Expose `notificationSchedulerProvider` cho toàn bộ ứng dụng.
3. Mắc nối tự động:
   - Trong `ReportsSettingsController.updateNotificationsEnabled`.
   - Trong `PlansController.createScheduledItem` và `markScheduledItemPaid`.
   - Trong `TransactionController.postTransaction` và `editTransaction`.
4. Bổ sung nút `btn_test_notification` ("Gửi thông báo kiểm tra ngay") trong `SettingsScreen`.
5. Tạo `test/unit/notification_scheduler_test.dart` và bổ sung widget test trong `test/widget/features_widget_test.dart`.

Chi tiết toàn bộ mã đề xuất đã được ghi đầy đủ tại `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\report.md`.

---

## 5. Verification Method

1. **Kiểm tra biên dịch & phân tích tĩnh**:
   ```powershell
   flutter analyze
   ```
   Kỳ vọng: 0 lỗi, 0 cảnh báo.
2. **Kiểm tra định dạng**:
   ```powershell
   dart format --output=none --set-exit-if-changed .
   ```
   Kỳ vọng: exit code 0.
3. **Chạy toàn bộ kiểm thử hiện hữu và mới**:
   ```powershell
   flutter test
   ```
   Kỳ vọng: Toàn bộ kiểm thử unit, database và widget đều pass (>= 275 tests).
4. **Xác minh trực quan trên Android Emulator (nếu có)**:
   - Vào tab "Kế hoạch & Báo cáo" -> "Cài đặt & Sao lưu".
   - Nhấn "Gửi thông báo kiểm tra ngay" -> Xác minh banner thông báo "Đồng Tiền — Kiểm tra thông báo" hiển thị tức thì trên đỉnh màn hình Android.
   - Thêm giao dịch chi tiêu vượt 80% ngân sách danh mục Ăn uống -> Xác minh thông báo "Cảnh báo ngân sách Ăn uống" hiển thị.

