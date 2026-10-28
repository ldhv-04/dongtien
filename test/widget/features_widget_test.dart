import 'package:dongtien/app/app.dart';
import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/core/notifications/notification_scheduler.dart';
import 'package:dongtien/domain/budgeting/category_budget_progress.dart';
import 'package:dongtien/domain/budgeting/category_spending_calculator.dart';
import 'package:dongtien/domain/forecasting/safe_to_spend_calculator.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dongtien/features/dashboard/presentation/providers/safe_to_spend_provider.dart';
import 'package:dongtien/features/plans/presentation/providers/plans_providers.dart';
import 'package:dongtien/features/reports_settings/presentation/providers/reports_settings_providers.dart';
import 'package:dongtien/features/reports_settings/presentation/reports_screen.dart';
import 'package:dongtien/features/reports_settings/presentation/settings_screen.dart';
import 'package:dongtien/features/transactions/presentation/controllers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_timezone'),
            (call) async {
      if (call.method == 'getLocalTimezone') {
        return 'Asia/Ho_Chi_Minh';
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('dexterous.com/flutter/local_notifications'),
            (call) async {
      if (call.method == 'initialize') {
        return true;
      }
      if (call.method == 'requestNotificationsPermission') {
        return null;
      }
      return null;
    });
  });

  group('Full App Navigation & Feature Screens Widget Tests', () {
    testWidgets(
        'MainNavigationShell switches across all 4 tabs and renders screens',
        (tester) async {
      const safeToSpendZero = SafeToSpendResult(
        safeToSpend: VndMoney.zero,
        dailyAllowance: VndMoney.zero,
        isDeficit: false,
        daysRemaining: 30,
        breakdown: SafeToSpendBreakdown(
          liquidAssets: VndMoney.zero,
          protectedReserves: VndMoney.zero,
          unfundedCommittedOutflows: VndMoney.zero,
          minimumCashBuffer: VndMoney.zero,
          billAllocations: [],
          envelopeCoverages: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            safeToSpendProvider
                .overrideWithValue(const AsyncValue.data(safeToSpendZero)),
            liquidAssetsStreamProvider.overrideWith((ref) => Stream.value(0)),
            accountsWithBalancesStreamProvider
                .overrideWith((ref) => Stream.value([])),
            settingsStreamProvider.overrideWith(
              (ref) => Stream.value(
                const Setting(
                  id: 1,
                  minimumCashBufferVnd: 0,
                  periodStartDay: 1,
                  dailyReminderHour: 20,
                  dailyReminderMinute: 0,
                  notificationsEnabled: false,
                  schemaVersion: 1,
                ),
              ),
            ),
            currentMonthlyBudgetSummaryProvider.overrideWith(
              (ref) => Stream.value(
                const MonthlyBudgetSummary(
                  yearMonth: 202610,
                  categoryProgresses: [],
                ),
              ),
            ),
            pendingBillsStreamProvider.overrideWith((ref) => Stream.value([])),
            nextPlannedIncomeStreamProvider
                .overrideWith((ref) => Stream.value(null)),
            envelopesStreamProvider.overrideWith((ref) => Stream.value([])),
            recentTransactionsStreamProvider
                .overrideWith((ref) => Stream.value([])),
            cleanTransactionsStreamProvider
                .overrideWith((ref) => Stream.value([])),
            allPostingsStreamProvider.overrideWith((ref) => Stream.value([])),
            categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
            netWorthStreamProvider.overrideWith((ref) => Stream.value(0)),
            allScheduledItemsStreamProvider
                .overrideWith((ref) => Stream.value([])),
          ],
          child: const DongTienApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 0: Dashboard
      expect(find.text('Đồng Tiền'), findsOneWidget);
      expect(find.text('Tổng quan'), findsOneWidget);

      // Switch to Tab 1: Giao dịch
      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();
      expect(find.text('Tài khoản'), findsWidgets);

      // Switch to Tab 2: Quỹ tiền
      await tester.tap(find.text('Quỹ tiền'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Quỹ'), findsWidgets);

      // Switch to Tab 3: Kế hoạch
      await tester.tap(find.text('Kế hoạch'));
      await tester.pumpAndSettle();
      expect(find.text('Ngân sách'), findsWidgets);
    });

    testWidgets(
        'ReportsScreen renders zero-income state with "Chưa có thu nhập", "Thu hồi chi phí ròng", and Net Worth',
        (tester) async {
      final report = CategorySpendingCalculator.calculate(
        categoryItems: [
          CategorySpendingItem(
            categoryId: 1,
            categoryName: 'Mua sắm',
            grossExpense: VndMoney(200000),
            refundCredits: VndMoney(250000),
          ),
        ],
        recognizedIncome: VndMoney.zero,
      );

      final summaryData = ReportsSummaryData(
        currentPeriodMonth: '2026-10',
        spendingReport: report,
        internalTransfersTotal: VndMoney.zero,
        totalAssets: VndMoney(5000000),
        totalLiabilities: VndMoney(800000),
        netWorth: VndMoney(4200000),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportsSummaryProvider.overrideWith((ref) async => summaryData),
          ],
          child: const MaterialApp(
            home: ReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Báo cáo tài chính'), findsOneWidget);
      expect(find.text('Chưa có thu nhập'), findsOneWidget);
      expect(find.text('Thu hồi chi phí ròng'), findsWidgets);
      expect(find.text('Tài sản ròng (Net Worth)'), findsOneWidget);
      expect(find.text('4.200.000 ₫'), findsOneWidget);
    });

    testWidgets(
        'SettingsScreen renders cash buffer, period start day, backup buttons, and sample data generator',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsStreamProvider.overrideWith(
              (ref) => Stream.value(
                const Setting(
                  id: 1,
                  minimumCashBufferVnd: 500000,
                  periodStartDay: 1,
                  dailyReminderHour: 20,
                  dailyReminderMinute: 0,
                  notificationsEnabled: false,
                  schemaVersion: 1,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cài đặt & Sao lưu'), findsOneWidget);
      expect(find.text('Khoản đệm tiền mặt tối thiểu'), findsOneWidget);
      expect(find.text('500.000 ₫'), findsOneWidget);
      expect(find.text('Tạo bản sao lưu mã hóa (.json)'), findsOneWidget);
      expect(find.text('Tạo dữ liệu mẫu'), findsOneWidget);
      expect(find.text('Gửi thông báo kiểm tra ngay'), findsOneWidget);
    });

    testWidgets(
        'SettingsScreen btn_test_notification triggers test notification and shows snackbar',
        (tester) async {
      final scheduler = NotificationScheduler(initialPermissionGranted: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationSchedulerProvider.overrideWithValue(scheduler),
            settingsStreamProvider.overrideWith(
              (ref) => Stream.value(
                const Setting(
                  id: 1,
                  minimumCashBufferVnd: 500000,
                  periodStartDay: 1,
                  dailyReminderHour: 20,
                  dailyReminderMinute: 0,
                  notificationsEnabled: true,
                  schemaVersion: 1,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gửi thông báo kiểm tra ngay'), findsOneWidget);
      await tester.ensureVisible(find.text('Gửi thông báo kiểm tra ngay'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi thông báo kiểm tra ngay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
          find.text('Đã gửi thông báo kiểm tra thành công!'), findsOneWidget);
    });

    testWidgets(
        'SettingsScreen displays permission banner when notification permission is denied',
        (tester) async {
      final scheduler = NotificationScheduler(initialPermissionGranted: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationSchedulerProvider.overrideWithValue(scheduler),
            settingsStreamProvider.overrideWith(
              (ref) => Stream.value(
                const Setting(
                  id: 1,
                  minimumCashBufferVnd: 500000,
                  periodStartDay: 1,
                  dailyReminderHour: 20,
                  dailyReminderMinute: 0,
                  notificationsEnabled: true,
                  schemaVersion: 1,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banner should be displayed
      expect(
        find.textContaining('Quyền thông báo đang tắt trên thiết bị'),
        findsOneWidget,
      );

      // Tapping test button when denied shows ruby warning snackbar
      await tester.ensureVisible(find.text('Gửi thông báo kiểm tra ngay'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi thông báo kiểm tra ngay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining('Quyền thông báo bị từ chối trên thiết bị'),
        findsOneWidget,
      );
    });
  });
}
