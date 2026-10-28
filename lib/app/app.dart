import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/envelopes/presentation/virtual_funds_screen.dart';
import '../features/plans/presentation/plans_screen.dart';
import '../features/transactions/presentation/quick_add_modal.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import 'theme/app_theme.dart';

/// Navigation state provider tracking the 4 bottom tabs.
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Main Application Entry Widget.
class DongTienApp extends StatelessWidget {
  const DongTienApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đồng Tiền',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [
        Locale('vi', 'VN'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainNavigationShell(),
    );
  }
}

/// Navigation Shell preserving state across the 4 bottom tabs using IndexedStack.
class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          DashboardScreen(),
          TransactionsScreen(),
          VirtualFundsScreen(),
          PlansScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(
            icon: Semantics(
              identifier: 'nav_tab_dashboard',
              child: const Icon(Icons.home_outlined),
            ),
            selectedIcon: Semantics(
              identifier: 'nav_tab_dashboard',
              child: const Icon(Icons.home),
            ),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Semantics(
              identifier: 'nav_tab_transactions',
              child: const Icon(Icons.account_balance_wallet_outlined),
            ),
            selectedIcon: Semantics(
              identifier: 'nav_tab_transactions',
              child: const Icon(Icons.account_balance_wallet),
            ),
            label: 'Giao dịch',
          ),
          NavigationDestination(
            icon: Semantics(
              identifier: 'nav_tab_funds',
              child: const Icon(Icons.eco_outlined),
            ),
            selectedIcon: Semantics(
              identifier: 'nav_tab_funds',
              child: const Icon(Icons.eco),
            ),
            label: 'Quỹ tiền',
          ),
          NavigationDestination(
            icon: Semantics(
              identifier: 'nav_tab_plans',
              child: const Icon(Icons.pie_chart_outline),
            ),
            selectedIcon: Semantics(
              identifier: 'nav_tab_plans',
              child: const Icon(Icons.pie_chart),
            ),
            label: 'Kế hoạch',
          ),
        ],
      ),
      floatingActionButton: Semantics(
        identifier: 'fab_quick_add',
        button: true,
        child: FloatingActionButton(
          onPressed: () => _openQuickAdd(context),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  void _openQuickAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickAddModal(),
    );
  }
}
