import 'package:dongtien/app/app.dart';
import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Đồng Tiền End-to-End Integration Flow', (tester) async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );
    addTearDown(() async => db.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const DongTienApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify clean 0 ₫ initial state on Dashboard
    expect(find.text('Đồng Tiền'), findsOneWidget);
    expect(find.text('0 ₫'), findsWidgets);

    // Navigate across all 4 bottom tabs
    await tester.tap(find.text('Giao dịch'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quỹ tiền'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kế hoạch'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tổng quan'));
    await tester.pumpAndSettle();
  });
}
