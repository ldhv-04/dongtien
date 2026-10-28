# Báo cáo Điều tra & Khảo sát Chi tiết — Yêu cầu R2 (On-Screen Notification Delivery & Verification)

**Mã phân công**: `explorer_survey_2`  
**Thời gian hoàn thành khảo sát**: 2026-10-28T00:52:00Z  
**Mục tiêu**: Điều tra toàn diện hiện trạng mã nguồn, phân tích kiến trúc, xác định điểm nghẽn và đưa ra giải pháp triển khai chi tiết cho Yêu cầu R2: Cơ chế thông báo đẩy trên màn hình Android 14 (`POST_NOTIFICATIONS`), múi giờ thực địa phương qua `flutter_timezone`, nhà cung cấp Riverpod dùng chung, tự động lên lịch/cảnh báo ngân sách (80%/100%), và nút kiểm tra thông báo tức thì trên `SettingsScreen`.

---

## 1. Tóm tắt Phát hiện Cốt lõi (Executive Summary)

1. **Khởi tạo Múi giờ (`flutter_timezone`)**: `pubspec.yaml` đã khóa sẵn `flutter_timezone: ^3.0.1`, `flutter_local_notifications: ^17.2.3` và `timezone: ^0.9.4`. Tuy nhiên, `lib/core/notifications/notification_scheduler.dart` hiện chỉ gọi `tz_data.initializeTimeZones()` mà **chưa hề gọi `tz.setLocalLocation()`**. Do đó, `tz.local` luôn mặc định là UTC, dẫn đến việc nhắc nhở lúc 20:00 bị lệch 7 tiếng so với giờ Việt Nam (`Asia/Ho_Chi_Minh` UTC+7).
2. **Quyền chạy Android 13/14+ (`POST_NOTIFICATIONS`)**: `android/app/src/main/AndroidManifest.xml` đã khai báo đúng quyền `POST_NOTIFICATIONS` và `RECEIVE_BOOT_COMPLETED` (không có exact alarm, hoàn toàn hợp chuẩn Android 12–15+). Tuy nhiên trong Dart, `NotificationScheduler` chưa gọi `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`, khiến trên Android 13/14+ ứng dụng không bao giờ hiển thị hộp thoại xin cấp quyền hệ thống lúc chạy.
3. **Quản lý trạng thái & Nhà cung cấp Riverpod**: Hiện chưa có `notificationSchedulerProvider`. `SettingsScreen` đang tự tạo một thực thể cục bộ riêng (`final NotificationScheduler _scheduler = NotificationScheduler();`), cô lập hoàn toàn với các controller khác.
4. **Mắc nối Tự động (Wiring)**:
   - **Bật/tắt thông báo trong Cài đặt**: `ReportsSettingsController.updateNotificationsEnabled` chỉ ghi vào SQLite `settings`, không gọi scheduler để lập lịch hoặc hủy thông báo.
   - **Tạo/thanh toán hóa đơn**: `PlansController.createScheduledItem` và `markScheduledItemPaid` không gọi `NotificationScheduler.reconcileAndSchedule`.
   - **Vượt ngưỡng ngân sách danh mục (80% / 100%)**: `TransactionController.postTransaction` và `editTransaction` không kiểm tra tiến độ ngân sách danh mục chi phí sau khi ghi sổ, khiến `triggerBudgetThresholdAlert` không bao giờ được kích hoạt tự động trong luồng người dùng.
5. **Nút kiểm tra thông báo**: `SettingsScreen` chưa có nút "Gửi thông báo kiểm tra ngay" với nhãn Semantics `btn_test_notification`.
6. **Kiểm thử**: Toàn bộ 275 test hiện tại đều pass, nhưng chưa có unit test chuyên biệt cho `NotificationScheduler` (múi giờ fallback, quyền bị từ chối, cảnh báo ngân sách từ DB, nút kiểm tra trên UI).

---

## 2. Khảo sát Chi tiết Từng Thành phần & Khuyến nghị Triển khai

### 2.1. `NotificationScheduler` (`lib/core/notifications/notification_scheduler.dart`)

#### Hiện trạng:
- Dòng 2–3: Chỉ import `timezone/data/latest_all.dart` và `timezone/timezone.dart`. Chưa import `flutter_timezone`.
- Dòng 27–41 (`initialize`):
  ```dart
  tz_data.initializeTimeZones();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await _plugin.initialize(initSettings);
  _initialized = true;
  ```
  -> `tz.setLocalLocation` không được gọi.
  -> `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()` không được gọi.
- Dòng 141–175 (`triggerBudgetThresholdAlert`):
  -> Chỉ có hàm nhận tham số tĩnh, chưa có phương thức kiểm tra tự động từ SQLite `AppDatabase`.
  -> Không tự khởi tạo nếu `_initialized == false`.
- Thiếu các phương thức: `showTestNotification()`, `cancelAll()`, `reconcileFromDatabase(AppDatabase db)`, `checkCategoryBudgetAlert({required AppDatabase db, required int categoryId})`.

#### Khuyến nghị Triển khai Cụ thể:
1. **Import `package:flutter_timezone/flutter_timezone.dart`** và `package:flutter_riverpod/flutter_riverpod.dart`.
2. **Khởi tạo Múi giờ với Fallback an toàn**:
   ```dart
   tz_data.initializeTimeZones();
   try {
     final timeZoneName = await FlutterTimezone.getLocalTimezone();
     tz.setLocalLocation(tz.getLocation(timeZoneName));
   } catch (_) {
     try {
       tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
     } catch (_) {
       // Giữ UTC nếu môi trường test không có dữ liệu timezone
     }
   }
   ```
3. **Yêu cầu Quyền Runtime trên Android 13/14+**:
   ```dart
   try {
     final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
         AndroidFlutterLocalNotificationsPlugin>();
     if (androidPlugin != null) {
       final granted = await androidPlugin.requestNotificationsPermission();
       if (granted != null) {
         _permissionGranted = granted;
       }
     }
   } catch (_) {
     // Graceful degradation trên desktop/headless test runner
   }
   ```
4. **Bổ sung `showTestNotification()`**:
   Hiển thị ngay thông báo biểu ngữ trên màn hình (heads-up banner) với mức ưu tiên cao nhất:
   - Kênh: `dongtien_test_channel`
   - Tên kênh: `'Thông báo kiểm tra'`
   - Mô tả: `'Kênh kiểm tra thông báo tức thì trên thiết bị'`
   - `importance: Importance.max`, `priority: Priority.max`
   - Tiêu đề: `'Đồng Tiền — Kiểm tra thông báo'`
   - Nội dung: `'Hệ thống thông báo tức thì hoạt động bình thường trên thiết bị!'`
   - ID: `9999`
5. **Bổ sung `cancelAll()`**:
   ```dart
   Future<void> cancelAll() async {
     try {
       if (_initialized) {
         await _plugin.cancelAll();
       }
     } catch (_) {}
   }
   ```
6. **Bổ sung `reconcileFromDatabase(AppDatabase db)`**:
   Tự động truy vấn bảng `settings` và các hóa đơn có `status = 'PENDING'` từ `db` để gọi `reconcileAndSchedule`. Nếu `setting.notificationsEnabled == false`, tự động hủy tất cả thông báo đã lên lịch.
7. **Bổ sung `checkCategoryBudgetAlert({required AppDatabase db, required int categoryId})`**:
   - Truy vấn cài đặt `settings` (nếu thông báo tắt hoặc không có quyền -> thoát sớm).
   - Xác định chu kỳ tháng hiện tại (`yearMonth = now.year * 100 + now.month`).
   - Lấy giới hạn ngân sách `limitVnd` của danh mục từ bảng `category_budgets`. Nếu không có ngân sách hoặc `limitVnd <= 0` -> thoát.
   - Truy vấn chi tiêu ròng trong tháng của danh mục đó qua câu lệnh SQL an toàn (sử dụng dấu nháy đơn `'POSTED'` và `'REVERSAL'`):
     ```sql
     SELECT COALESCE(SUM(p.debit_vnd), 0) - COALESCE(SUM(p.credit_vnd), 0) AS net_spent
     FROM journal_postings p
     JOIN journal_transactions t ON p.transaction_id = t.id
     WHERE p.category_id = ? AND t.occurred_at >= ? AND t.occurred_at < ?
       AND t.status = 'POSTED' AND t.tx_type != 'REVERSAL'
     ```
   - Nếu `net_spent >= (limitVnd * 80) ~/ 100`: kích hoạt `triggerBudgetThresholdAlert` với tiêu đề phù hợp (vượt 100% hoặc cảnh báo 80%).

---

### 2.2. Chia sẻ Provider Riverpod (`notificationSchedulerProvider`)

#### Khuyến nghị Triển khai:
Khai báo trực tiếp trong `lib/core/notifications/notification_scheduler.dart`:
```dart
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler();
});
```
Điều này cho phép:
- Mọi màn hình (`SettingsScreen`) và controller (`TransactionController`, `PlansController`, `ReportsSettingsController`) có thể đọc chung một instance qua `ref.read(notificationSchedulerProvider)`.
- Môi trường kiểm thử có thể override dễ dàng qua `notificationSchedulerProvider.overrideWithValue(mockScheduler)`.

---

### 2.3. Tự động hóa Lập lịch & Cảnh báo (Automatic Scheduling & Alerting)

#### 1. Khi bật/tắt Thông báo trong Cài đặt:
- **Tập tin**: `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`
- **Vị trí**: Hàm `ReportsSettingsController.updateNotificationsEnabled(bool enabled)` (dòng 178–188).
- **Cải tiến**:
  ```dart
  Future<void> updateNotificationsEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await (_db.update(_db.settings)..where((s) => s.id.equals(1))).write(
        SettingsCompanion(
          notificationsEnabled: Value(enabled),
        ),
      );
      ref.invalidate(settingsStreamProvider);

      final scheduler = ref.read(notificationSchedulerProvider);
      if (enabled) {
        await scheduler.initialize();
        await scheduler.reconcileFromDatabase(_db);
      } else {
        await scheduler.cancelAll();
      }
    });
  }
  ```

#### 2. Khi tạo hoặc thanh toán Hóa đơn:
- **Tập tin**: `lib/features/plans/presentation/providers/plans_providers.dart`
- **Vị trí**:
  - `PlansController.createScheduledItem` (dòng 261–295): Sau khi insert bản ghi thành công, nếu `kind == 'BILL'`, gọi `await ref.read(notificationSchedulerProvider).reconcileFromDatabase(db);`.
  - `PlansController.markScheduledItemPaid` (dòng 299–466): Sau khi cập nhật trạng thái hóa đơn thành `PAID_OR_RECEIVED`, gọi:
    ```dart
    final scheduler = ref.read(notificationSchedulerProvider);
    await scheduler.reconcileFromDatabase(db);
    if (item.categoryId != null) {
      await scheduler.checkCategoryBudgetAlert(
        db: db,
        categoryId: item.categoryId!,
      );
    }
    ```

#### 3. Khi giao dịch chi tiêu làm ngân sách vượt ngưỡng 80% hoặc 100%:
- **Tập tin**: `lib/features/transactions/presentation/controllers/transaction_controller.dart`
- **Vị trí**:
  - `TransactionController.postTransaction` (dòng 13–37):
    Sau khi `dao.postTransactionCommand(command)` thành công:
    ```dart
    final catIds = command.postings
        .where((p) => p.categoryId != null && p.debitVnd > 0)
        .map((p) => p.categoryId!)
        .toSet();
    final scheduler = ref.read(notificationSchedulerProvider);
    for (final catId in catIds) {
      await scheduler.checkCategoryBudgetAlert(db: db, categoryId: catId);
    }
    ```
  - `TransactionController.editTransaction` (dòng 54–76):
    Thực hiện tương tự sau khi ghi nhận giao dịch thay thế `newCommand`.

---

### 2.4. Nút "Gửi thông báo kiểm tra ngay" trên `SettingsScreen`

- **Tập tin**: `lib/features/reports_settings/presentation/settings_screen.dart`
- **Vị trí**:
  1. Loại bỏ biến thành viên `final NotificationScheduler _scheduler = NotificationScheduler();` ở dòng 21. Thay bằng `ref.watch(notificationSchedulerProvider)` / `ref.read(notificationSchedulerProvider)`.
  2. Tại `initState()`, kiểm tra trạng thái quyền:
     ```dart
     WidgetsBinding.instance.addPostFrameCallback((_) {
       final scheduler = ref.read(notificationSchedulerProvider);
       if (!scheduler.isPermissionGranted) {
         setState(() => _permissionDeniedBanner = true);
       }
     });
     ```
  3. Trong thẻ `_buildFinancialRulesCard`, ngay sau `SwitchListTile` (`toggle_notifications`), chèn khoảng cách `AppSpacing.gapH8` và thêm nút:
     ```dart
     Semantics(
       identifier: 'btn_test_notification',
       button: true,
       child: OutlinedButton.icon(
         icon: const Icon(Icons.notification_important_outlined),
         label: const Text('Gửi thông báo kiểm tra ngay'),
         onPressed: () async {
           final scheduler = ref.read(notificationSchedulerProvider);
           final granted = await scheduler.initialize();
           if (mounted) {
             setState(() {
               _permissionDeniedBanner = !granted;
             });
           }
           if (granted) {
             await scheduler.showTestNotification();
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text('Đã gửi thông báo kiểm tra thành công!'),
                 ),
               );
             }
           } else {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   backgroundColor: AppColors.surfaceAccentRubyPrimary,
                   content: Text('Không thể gửi: Quyền thông báo bị từ chối trên thiết bị.'),
                 ),
               );
             }
           }
         },
       ),
     ),
     ```

---

## 3. Khảo sát Cấu hình Android (`AndroidManifest.xml` & `build.gradle`)

1. **`android/app/src/main/AndroidManifest.xml`**:
   - Đã có dòng 3: `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`.
   - Đã có dòng 4: `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>`.
   - Đã có `ScheduledNotificationReceiver` và `ScheduledNotificationBootReceiver`.
   - Không có quyền `SCHEDULE_EXACT_ALARM` hay `USE_EXACT_ALARM` -> **100% tuân thủ quy định Google Play & Android 14+**.
2. **`android/app/build.gradle`**:
   - `compileSdk = 35`, `targetSdk = 34` (Android 14) -> Đúng môi trường runtime yêu cầu `POST_NOTIFICATIONS`.
   - `coreLibraryDesugaringEnabled true` với `desugar_jdk_libs:2.0.4` -> Sẵn sàng cho `flutter_local_notifications`.

---

## 4. Kế hoạch Kiểm thử & Ma trận Xác minh (Test Verification Plan)

### 4.1. Unit Tests Cần Thêm Mới (`test/unit/notification_scheduler_test.dart`)
1. **Kiểm tra Fallback Múi giờ**:
   - Gọi `initializeTimeZones()`, khi `FlutterTimezone.getLocalTimezone()` ném ngoại lệ -> scheduler tự động fallback về `tz.getLocation('Asia/Ho_Chi_Minh')`.
   - Xác minh `tz.local.name == 'Asia/Ho_Chi_Minh'`.
2. **Kiểm tra Trạng thái Quyền (`initialPermissionGranted: false`)**:
   - Khi quyền bị từ chối: `isPermissionGranted == false`.
   - `reconcileAndSchedule` không lên lịch bất kỳ thông báo nào.
   - `triggerBudgetThresholdAlert` không bắn thông báo và không ném ngoại lệ.
3. **Kiểm tra Ngưỡng Cảnh báo Ngân sách (80% / 100%)**:
   - Dưới 80%: không gửi thông báo.
   - Đạt 80%–99%: gửi thông báo kênh `dongtien_budget_alerts` với tiêu đề "Cảnh báo ngân sách".
   - Đạt >= 100%: gửi thông báo kênh `dongtien_budget_alerts` với tiêu đề "Vượt ngân sách".
4. **Kiểm tra `checkCategoryBudgetAlert` từ SQLite in-memory**:
   - Tạo ngân sách 1.000.000 ₫ cho danh mục Ăn uống.
   - Chi tiêu 500.000 ₫ (50%) -> không có alert.
   - Chi tiêu thêm 350.000 ₫ (tổng 850.000 ₫ = 85%) -> kích hoạt alert ngưỡng 80%.
   - Chi tiêu thêm 200.000 ₫ (tổng 1.050.000 ₫ = 105%) -> kích hoạt alert vượt ngân sách 100%.
   - Nếu `setting.notificationsEnabled == false` -> không alert.
5. **Kiểm tra `showTestNotification`**:
   - Kích hoạt notification ID 9999 trên kênh `dongtien_test_channel`.

### 4.2. Widget Tests Cần Bổ sung / Mở rộng (`test/widget/features_widget_test.dart`)
1. **Kiểm tra Render `btn_test_notification`**:
   - Render `SettingsScreen`.
   - Tìm widget với `Semantics(identifier: 'btn_test_notification')` và nhãn "Gửi thông báo kiểm tra ngay".
2. **Kiểm tra Nhấn nút Test Notification**:
   - Tap vào `btn_test_notification`.
   - Xác minh `showSnackBar` hiển thị "Đã gửi thông báo kiểm tra thành công!".
3. **Kiểm tra Hiển thị Biểu ngữ Quyền bị từ chối**:
   - Override `notificationSchedulerProvider` với scheduler có `isPermissionGranted == false`.
   - Xác minh biểu ngữ `Quyền thông báo đang tắt trên thiết bị...` hiển thị trên màn hình.

---

## 5. Bảng Đối chiếu Files Cần Tác động khi Thực thi (Implementation Matrix)

| Đường dẫn Tập tin | Dòng | Nội dung Thay đổi |
|---|---|---|
| `lib/core/notifications/notification_scheduler.dart` | 1–40 | Thêm import `flutter_timezone`, `flutter_riverpod`. Khởi tạo timezone với fallback `Asia/Ho_Chi_Minh`. Gọi `requestNotificationsPermission()`. Khai báo `notificationSchedulerProvider`. |
| `lib/core/notifications/notification_scheduler.dart` | 42–176 | Thêm `showTestNotification()`, `cancelAll()`, `reconcileFromDatabase()`, `checkCategoryBudgetAlert()`. |
| `lib/features/reports_settings/presentation/settings_screen.dart` | 21, 230–245 | Đổi từ `_scheduler` cục bộ sang `notificationSchedulerProvider`. Thêm nút `btn_test_notification` ("Gửi thông báo kiểm tra ngay"). |
| `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart` | 178–188 | Thêm gọi `scheduler.initialize()` + `reconcileFromDatabase()` khi bật, và `cancelAll()` khi tắt. |
| `lib/features/plans/presentation/providers/plans_providers.dart` | 261–295, 299–466 | Gọi `reconcileFromDatabase()` khi tạo hóa đơn và thanh toán hóa đơn; gọi `checkCategoryBudgetAlert()` khi hóa đơn có gắn danh mục. |
| `lib/features/transactions/presentation/controllers/transaction_controller.dart` | 13–76 | Gọi `checkCategoryBudgetAlert()` sau khi ghi nhận chi tiêu hoặc chỉnh sửa giao dịch. |
| `test/unit/notification_scheduler_test.dart` | Tạo mới | Unit tests cho timezone, quyền runtime, ngưỡng ngân sách, DB query. |
| `test/widget/features_widget_test.dart` | 150–182 | Bổ sung kiểm thử widget cho `btn_test_notification` và banner cấp quyền. |

