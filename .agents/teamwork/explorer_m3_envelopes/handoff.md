# HANDOFF REPORT — VIRTUAL FUNDS (QUỸ TIỀN) UI BLUEPRINT (TAB 2)

**Agent**: `explorer_m3_envelopes`  
**Milestone**: M3 (UI Feature Track — Virtual Funds)  
**Target Recipient**: `orchestrator_1` / `worker_m3_envelopes`  
**Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m3_envelopes`

---

## 1. OBSERVATION

Direct evidence observed from the codebase, documentation, and database contracts:

### 1.1 Existing Database Contracts & DAOs
1. **`lib/core/database/app_database.dart` (lines 107–127)**:
   - `Envelopes` table:
     ```dart
     IntColumn get id => integer().autoIncrement()();
     TextColumn get name => text()();
     TextColumn get policy => text()(); // CHECK (policy IN ('PROTECTED', 'FLEXIBLE'))
     IntColumn get reservedBalanceVnd => integer().withDefault(const Constant(0))();
     BoolColumn get allowNegativeException => boolean().withDefault(const Constant(false))();
     IntColumn get targetAmountVnd => integer().nullable()();
     IntColumn get targetDateMs => integer().nullable()();
     IntColumn get periodLimitVnd => integer().nullable()();
     BoolColumn get rolloverEnabled => boolean().withDefault(const Constant(false))();
     IntColumn get priority => integer().withDefault(const Constant(1))();
     BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
     ```
2. **`lib/core/database/app_database.dart` (lines 135–160)**:
   - `EnvelopeMovements` table:
     ```dart
     IntColumn get id => integer().autoIncrement()();
     TextColumn get movementType => text()(); // 'ALLOCATE', 'RELEASE', 'TRANSFER', 'SPEND', 'REFUND_RESTORE', 'REVERSAL'
     IntColumn get amountVnd => integer()(); // CHECK (amount_vnd > 0)
     IntColumn get sourceEnvelopeId => integer().nullable().references(Envelopes, #id, onDelete: KeyAction.restrict)();
     IntColumn get destEnvelopeId => integer().nullable().references(Envelopes, #id, onDelete: KeyAction.restrict)();
     IntColumn get linkedTransactionId => integer().nullable().references(JournalTransactions, #id, onDelete: KeyAction.setNull)();
     IntColumn get linkedObligationId => integer().nullable().references(ScheduledItems, #id, onDelete: KeyAction.setNull)();
     IntColumn get occurredAt => integer()();
     ```
3. **`lib/core/database/daos/envelope_dao.dart` (lines 15–229)**:
   - `getAvailableToAllocate(int totalLiquidAssetsVnd) -> Future<int>`
   - `allocate({required int envelopeId, required int amountVnd, required int totalLiquidAssetsVnd}) -> Future<int>` (Throws `OverAllocationException`)
   - `release({required int envelopeId, required int amountVnd}) -> Future<int>` (Throws `SpendingDeficitException` if `amount > reserved` & `!allowNegativeException`)
   - `transfer({required int fromEnvelopeId, required int toEnvelopeId, required int amountVnd}) -> Future<int>` (Throws `InvalidEnvelopeOperationException` if `from == to`, throws `SpendingDeficitException` if `amount > sourceReserved` & `!allowNegativeException`)
   - `watchAllEnvelopes() -> Stream<List<Envelope>>` (orders by `priority` ascending, filters `isArchived == false`)
   - `watchMovementsForEnvelope(int envelopeId) -> Stream<List<EnvelopeMovement>>` (orders by `occurredAt DESC, id DESC`)
   - CRITICAL: All envelope operations execute inside `db.transaction()` and generate **ZERO general ledger postings**.
4. **`lib/core/database/daos/ledger_dao.dart` (lines 468–482)**:
   - `watchTotalLiquidAssets() -> Stream<int>`: reactive stream of total liquid cash across `ASSET_CASH` and `ASSET_BANK` where `is_liquid == true`.

### 1.2 Domain Invariants & Rules
1. **`lib/domain/envelopes/available_to_allocate.dart` (lines 8–29)**:
   - Equation: `available_to_allocate = total_liquid_assets - total_envelope_reserves - minimum_cash_buffer_vnd`.
   - `validateAllocation`: enforces `allocateAmountVnd <= max(0, availableToAllocateVnd)`.
   - `validateTransfer`: enforces `fromEnvelopeId != toEnvelopeId` and `amountVnd <= sourceReservedVnd` unless `allowNegativeException == true`.
2. **`lib/domain/envelopes/envelope_policy.dart`**:
   - `EnvelopePolicy.protected` (`'PROTECTED'`): Fixed commitments (emergency fund, rent, bills). Directly deducted in `Safe-to-Spend`.
   - `EnvelopePolicy.flexible` (`'FLEXIBLE'`): Discretionary reserves (dining out, shopping). Not deducted in `Safe-to-Spend`.
3. **`docs/DESIGN_AND_TEST_PLAN.md` (Sections 1, 3, 4.5)**:
   - Semantics identifiers for Virtual Funds:
     * `card_summary_liquid`, `card_summary_reserved`, `card_summary_available`
     * `btn_allocate_fund`, `btn_transfer_fund`, `btn_release_fund`
     * `card_envelope_<id>`, `screen_fund_detail`
   - Numeric & typography tokens: `FontFeature.tabularFigures()`, dot separator (`1.250.000 ₫`), 16px radius cards, light Material 3 colors.

### 1.3 Architectural Layer Invariants (`AGENTS.md` Section 3)
- `worker_m3_envelopes` has exclusive ownership of `lib/features/envelopes/`.
- Parallel feature workers must **NEVER** modify `lib/core/database/` or `lib/domain/` code. All envelope CRUD and view operations must interact with the existing Drift DAOs and database instances via dependency injection.

---

## 2. LOGIC CHAIN

Step-by-step reasoning from observations to implementation architecture:

1. **State Aggregation (Reactive Streams)**:
   - From Obs 1.1.4 and 1.1.3, liquid assets stream via `db.ledgerDao.watchTotalLiquidAssets()` and envelopes stream via `db.envelopeDao.watchAllEnvelopes()`.
   - The settings singleton (`settings.minimum_cash_buffer_vnd`) is observed via `(db.select(db.settings)..where((s) => s.id.equals(1))).watchSingle()`.
   - Therefore, a combined Riverpod provider `virtualFundsSummaryProvider` can compute in real time:
     * `totalLiquidAssets`
     * `totalReserved` = $\sum e.\text{reserved\_balance\_vnd}$
     * `minimumCashBuffer`
     * `availableToAllocate` = `totalLiquidAssets - totalReserved - minimumCashBuffer`
     * `isOverAllocated` = `availableToAllocate < 0`
     * `protectedEnvelopes` = list where `policy == 'PROTECTED'`
     * `flexibleEnvelopes` = list where `policy == 'FLEXIBLE'`
   - Whenever a transaction, allocation, release, or transfer occurs, Drift triggers stream emissions that instantly update the UI with zero manual polling.

2. **Over-Allocation Banner Trigger**:
   - From Obs 1.2.1 and Scenario 12, when `availableToAllocate < 0`, the user has allocated more money than liquid assets minus cash buffer.
   - The summary bar must display a prominent warning banner (`banner_over_allocation`) with Ruby styling (`AppColors.surfaceAccentRubySecondary`, `AppColors.textAccentRubyPrimary`), stating exact deficit `VndFormatter.format(availableToAllocate.abs())`.

3. **Envelope Categorization**:
   - From Obs 1.2.2, dividing envelopes into `PROTECTED` (Bảo vệ) and `FLEXIBLE` (Linh hoạt) aligns directly with the Safe-to-Spend domain model.
   - The UI presents two distinct sections:
     * "Quỹ bảo vệ (Bắt buộc)": displays lock icon, subtotal, and cards for emergency, bills, rent.
     * "Quỹ linh hoạt (Tùy chọn)": displays sliders/tune icon, subtotal, and cards for dining out, shopping, discretionary.

4. **Negative Balance (Deficit) Badge**:
   - From Obs 1.1.1 (`allowNegativeException`), an envelope can reach a negative balance if an overspend or release occurred.
   - When `reservedBalanceVnd < 0`, the card must render the balance in Ruby red and show a `"Thâm hụt"` badge (`badge_deficit_<id>`), with progress bar colored Ruby.

5. **Movement History Log**:
   - From Obs 1.1.2 and 1.1.3 (`watchMovementsForEnvelope`), each movement has a type:
     * `ALLOCATE`: Inflow (`+amount ₫`, Verdant icon/text).
     * `RELEASE`: Outflow (`-amount ₫`, Amber icon/text).
     * `TRANSFER`: Inflow or Outflow depending on whether this envelope is destination or source.
     * `SPEND`: Outflow (`-amount ₫`, Ruby icon/text, linked to journal transaction).
     * `REFUND_RESTORE`: Inflow (`+amount ₫`, Verdant icon/text).
     * `REVERSAL`: Reversal leg (`+` or `-` offsetting original).

6. **Keypad Integration for Modals**:
   - All monetary input in Allocate, Release, and Transfer modals uses the custom numeric keypad (`CustomKeypad`) to guarantee fast, error-free whole integer VND entry without soft-keyboard jitter.

---

## 3. CAVEATS

1. **Envelope Creation / Update / Archival**:
   - `EnvelopeDao` currently has `allocate`, `release`, `transfer`, `getAvailableToAllocate`, `watchAllEnvelopes`, `getAllEnvelopes`, `getEnvelopeById`, `watchMovementsForEnvelope`.
   - Because feature workers cannot modify `lib/core/database/daos/envelope_dao.dart` directly under the cross-layer mutation ban, the feature layer repository (`EnvelopeRepository` in `lib/features/envelopes/data/envelope_repository.dart`) performs envelope table writes using `db.into(db.envelopes).insert(...)` and `(db.update(db.envelopes)..where((e) => e.id.equals(id))).write(...)`. This respects layer boundaries completely.
2. **Deficit in Flexible vs Protected Envelopes**:
   - A negative balance in an envelope reduces `total_envelope_reserves` algebraically (because $\sum e.\text{reserved}$ decreases), which mathematically increases `available_to_allocate`. This is correct per Section 5.1 of `ARCHITECTURE_AND_RULES.md`.
3. **No External Charting Libraries**:
   - Progress indicators and summary visualizers must rely strictly on Flutter's built-in `LinearProgressIndicator` or the project's `ProgressBar` component, never third-party chart packages.

---

## 4. CONCLUSION & IMPLEMENTATION BLUEPRINT

The blueprint below is the complete, exhaustive implementation guide for `worker_m3_envelopes`.

### 4.1 Target Directory Layout (`lib/features/envelopes/`)

```text
lib/features/envelopes/
├── data/
│   └── envelope_repository.dart       # Database bridge for envelope CRUD & DAO delegation
├── domain/
│   ├── virtual_funds_summary.dart    # Aggregated summary state model
│   └── envelope_detail_state.dart     # Single envelope + movements state model
├── providers/
│   ├── envelope_providers.dart       # Riverpod Streams and State Providers
│   └── envelope_controller.dart      # Notifier / Controller for user actions
└── presentation/
    ├── virtual_funds_screen.dart     # Tab 2 Root Screen
    ├── envelope_detail_screen.dart   # Detail Screen with Movement History
    ├── widgets/
    │   ├── summary_header_bar.dart   # 3 Metric Cards + Cash Buffer row
    │   ├── over_allocation_banner.dart # Over-allocation warning banner
    │   ├── envelope_category_section.dart # Grouped section header & list
    │   ├── envelope_card.dart        # Envelope card with progress bar & deficit badge
    │   ├── movement_history_tile.dart # Chronological movement item tile
    │   └── quick_action_button.dart  # Pill button for Allocate/Release/Transfer
    └── modals/
        ├── allocate_modal.dart       # Allocate modal with keypad & guard
        ├── release_modal.dart        # Release modal with keypad & deficit guard
        ├── transfer_modal.dart       # Transfer modal with source/dest selector & keypad
        └── envelope_form_modal.dart  # Create/Edit envelope bottom sheet
```

---

### 4.2 Data Models & Domain State

#### `lib/features/envelopes/domain/virtual_funds_summary.dart`
```dart
import 'package:dongtien/core/database/app_database.dart';

/// Aggregated financial metrics for the Virtual Funds (Quỹ tiền) tab.
class VirtualFundsSummary {
  final int totalLiquidAssets;
  final int totalEnvelopeReserves;
  final int totalProtectedReserves;
  final int totalFlexibleReserves;
  final int minimumCashBuffer;
  final int availableToAllocate;
  final bool isOverAllocated;
  final int overAllocatedAmount;
  final List<Envelope> protectedEnvelopes;
  final List<Envelope> flexibleEnvelopes;

  const VirtualFundsSummary({
    required this.totalLiquidAssets,
    required this.totalEnvelopeReserves,
    required this.totalProtectedReserves,
    required this.totalFlexibleReserves,
    required this.minimumCashBuffer,
    required this.availableToAllocate,
    required this.isOverAllocated,
    required this.overAllocatedAmount,
    required this.protectedEnvelopes,
    required this.flexibleEnvelopes,
  });

  factory VirtualFundsSummary.compute({
    required int totalLiquidAssets,
    required List<Envelope> allEnvelopes,
    required int minimumCashBuffer,
  }) {
    final activeEnvelopes = allEnvelopes.where((e) => !e.isArchived).toList();

    int protectedSum = 0;
    int flexibleSum = 0;
    final protectedList = <Envelope>[];
    final flexibleList = <Envelope>[];

    for (final env in activeEnvelopes) {
      if (env.policy == 'PROTECTED') {
        protectedSum += env.reservedBalanceVnd;
        protectedList.add(env);
      } else {
        flexibleSum += env.reservedBalanceVnd;
        flexibleList.add(env);
      }
    }

    final totalReserved = protectedSum + flexibleSum;
    final available = totalLiquidAssets - totalReserved - minimumCashBuffer;
    final isOver = available < 0;
    final overAmount = isOver ? -available : 0;

    return VirtualFundsSummary(
      totalLiquidAssets: totalLiquidAssets,
      totalEnvelopeReserves: totalReserved,
      totalProtectedReserves: protectedSum,
      totalFlexibleReserves: flexibleSum,
      minimumCashBuffer: minimumCashBuffer,
      availableToAllocate: available,
      isOverAllocated: isOver,
      overAllocatedAmount: overAmount,
      protectedEnvelopes: protectedList,
      flexibleEnvelopes: flexibleList,
    );
  }
}
```

#### `lib/features/envelopes/domain/envelope_detail_state.dart`
```dart
import 'package:dongtien/core/database/app_database.dart';

/// State representation for an Envelope Detail Screen.
class EnvelopeDetailState {
  final Envelope envelope;
  final List<EnvelopeMovement> movements;
  final Map<int, String> envelopeNames; // ID -> Name lookup for transfers

  const EnvelopeDetailState({
    required this.envelope,
    required this.movements,
    required this.envelopeNames,
  });

  bool get isDeficit => envelope.reservedBalanceVnd < 0;

  double? get progressRatio {
    if (envelope.targetAmountVnd == null || envelope.targetAmountVnd! <= 0) {
      return null;
    }
    if (envelope.reservedBalanceVnd <= 0) return 0.0;
    return envelope.reservedBalanceVnd / envelope.targetAmountVnd!;
  }

  int? get targetShortfall {
    if (envelope.targetAmountVnd == null) return null;
    final diff = envelope.targetAmountVnd! - envelope.reservedBalanceVnd;
    return diff > 0 ? diff : 0;
  }
}
```

---

### 4.3 Data Layer & Riverpod Providers

#### `lib/features/envelopes/data/envelope_repository.dart`
```dart
import 'package:drift/drift.dart';
import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/domain/envelopes/envelope_policy.dart';

/// Repository abstracting persistence for envelopes and movements.
class EnvelopeRepository {
  final AppDatabase _db;
  EnvelopeRepository(this._db);

  Stream<List<Envelope>> watchAllEnvelopes() => _db.envelopeDao.watchAllEnvelopes();
  Future<List<Envelope>> getAllEnvelopes() => _db.envelopeDao.getAllEnvelopes();
  Future<Envelope?> getEnvelopeById(int id) => _db.envelopeDao.getEnvelopeById(id);
  Stream<List<EnvelopeMovement>> watchMovements(int id) => _db.envelopeDao.watchMovementsForEnvelope(id);

  Stream<int> watchTotalLiquidAssets() => _db.ledgerDao.watchTotalLiquidAssets();
  Stream<SettingsData> watchSettings() =>
      (_db.select(_db.settings)..where((s) => s.id.equals(1))).watchSingle();

  Future<int> allocate({
    required int envelopeId,
    required int amountVnd,
    required int totalLiquidAssetsVnd,
  }) =>
      _db.envelopeDao.allocate(
        envelopeId: envelopeId,
        amountVnd: amountVnd,
        totalLiquidAssetsVnd: totalLiquidAssetsVnd,
      );

  Future<int> release({
    required int envelopeId,
    required int amountVnd,
  }) =>
      _db.envelopeDao.release(
        envelopeId: envelopeId,
        amountVnd: amountVnd,
      );

  Future<int> transfer({
    required int fromEnvelopeId,
    required int toEnvelopeId,
    required int amountVnd,
  }) =>
      _db.envelopeDao.transfer(
        fromEnvelopeId: fromEnvelopeId,
        toEnvelopeId: toEnvelopeId,
        amountVnd: amountVnd,
      );

  Future<int> createEnvelope({
    required String name,
    required EnvelopePolicy policy,
    int? targetAmountVnd,
    DateTime? targetDate,
    bool allowNegativeException = false,
    int priority = 1,
  }) async {
    return _db.into(_db.envelopes).insert(
      EnvelopesCompanion.insert(
        name: name,
        policy: policy.dbValue,
        reservedBalanceVnd: const Value(0),
        allowNegativeException: Value(allowNegativeException),
        targetAmountVnd: Value(targetAmountVnd),
        targetDateMs: Value(targetDate?.millisecondsSinceEpoch),
        priority: Value(priority),
        isArchived: const Value(false),
      ),
    );
  }

  Future<void> updateEnvelope({
    required int id,
    required String name,
    required EnvelopePolicy policy,
    int? targetAmountVnd,
    DateTime? targetDate,
    required bool allowNegativeException,
    int priority = 1,
  }) async {
    await (_db.update(_db.envelopes)..where((e) => e.id.equals(id))).write(
      EnvelopesCompanion(
        name: Value(name),
        policy: Value(policy.dbValue),
        targetAmountVnd: Value(targetAmountVnd),
        targetDateMs: Value(targetDate?.millisecondsSinceEpoch),
        allowNegativeException: Value(allowNegativeException),
        priority: Value(priority),
      ),
    );
  }

  Future<void> archiveEnvelope(int id) async {
    await (_db.update(_db.envelopes)..where((e) => e.id.equals(id))).write(
      const EnvelopesCompanion(isArchived: Value(true)),
    );
  }
}
```

#### `lib/features/envelopes/providers/envelope_providers.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dongtien/core/database/app_database.dart';
import '../data/envelope_repository.dart';
import '../domain/virtual_funds_summary.dart';
import '../domain/envelope_detail_state.dart';

/// Database provider (injected at top level or inherited from app).
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

final envelopeRepositoryProvider = Provider<EnvelopeRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return EnvelopeRepository(db);
});

final envelopesStreamProvider = StreamProvider<List<Envelope>>((ref) {
  final repo = ref.watch(envelopeRepositoryProvider);
  return repo.watchAllEnvelopes();
});

final liquidAssetsStreamProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(envelopeRepositoryProvider);
  return repo.watchTotalLiquidAssets();
});

final settingsStreamProvider = StreamProvider<SettingsData>((ref) {
  final repo = ref.watch(envelopeRepositoryProvider);
  return repo.watchSettings();
});

/// Combined summary provider recomputing reactively whenever any stream updates.
final virtualFundsSummaryProvider = Provider<AsyncValue<VirtualFundsSummary>>((ref) {
  final envelopesAsync = ref.watch(envelopesStreamProvider);
  final liquidAsync = ref.watch(liquidAssetsStreamProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);

  if (envelopesAsync.isLoading || liquidAsync.isLoading || settingsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (envelopesAsync.hasError) return AsyncValue.error(envelopesAsync.error!, envelopesAsync.stackTrace!);
  if (liquidAsync.hasError) return AsyncValue.error(liquidAsync.error!, liquidAsync.stackTrace!);
  if (settingsAsync.hasError) return AsyncValue.error(settingsAsync.error!, settingsAsync.stackTrace!);

  final allEnvelopes = envelopesAsync.value ?? [];
  final liquid = liquidAsync.value ?? 0;
  final settings = settingsAsync.value;
  final buffer = settings?.minimumCashBufferVnd ?? 0;

  final summary = VirtualFundsSummary.compute(
    totalLiquidAssets: liquid,
    allEnvelopes: allEnvelopes,
    minimumCashBuffer: buffer,
  );

  return AsyncValue.data(summary);
});

/// Detail provider family for viewing a specific envelope.
final envelopeDetailProvider = StreamProvider.family<EnvelopeDetailState, int>((ref, envelopeId) async* {
  final repo = ref.watch(envelopeRepositoryProvider);
  final envelopesStream = repo.watchAllEnvelopes();
  final movementsStream = repo.watchMovements(envelopeId);

  await for (final envelopes in envelopesStream) {
    final movements = await repo.watchMovements(envelopeId).first;
    final currentEnv = envelopes.firstWhere(
      (e) => e.id == envelopeId,
      orElse: () => throw ArgumentError('Envelope not found: $envelopeId'),
    );

    final names = {for (final e in envelopes) e.id: e.name};

    yield EnvelopeDetailState(
      envelope: currentEnv,
      movements: movements,
      envelopeNames: names,
    );
  }
});
```

#### `lib/features/envelopes/providers/envelope_controller.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dongtien/domain/envelopes/envelope_policy.dart';
import 'envelope_providers.dart';

/// Controller executing user-initiated envelope mutations.
class EnvelopeController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> allocate({
    required int envelopeId,
    required int amountVnd,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      final liquid = await ref.read(liquidAssetsStreamProvider.future);
      await repo.allocate(
        envelopeId: envelopeId,
        amountVnd: amountVnd,
        totalLiquidAssetsVnd: liquid,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> release({
    required int envelopeId,
    required int amountVnd,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      await repo.release(envelopeId: envelopeId, amountVnd: amountVnd);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> transfer({
    required int fromEnvelopeId,
    required int toEnvelopeId,
    required int amountVnd,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      await repo.transfer(
        fromEnvelopeId: fromEnvelopeId,
        toEnvelopeId: toEnvelopeId,
        amountVnd: amountVnd,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createEnvelope({
    required String name,
    required EnvelopePolicy policy,
    int? targetAmountVnd,
    DateTime? targetDate,
    bool allowNegativeException = false,
    int priority = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      await repo.createEnvelope(
        name: name,
        policy: policy,
        targetAmountVnd: targetAmountVnd,
        targetDate: targetDate,
        allowNegativeException: allowNegativeException,
        priority: priority,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateEnvelope({
    required int id,
    required String name,
    required EnvelopePolicy policy,
    int? targetAmountVnd,
    DateTime? targetDate,
    required bool allowNegativeException,
    int priority = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      await repo.updateEnvelope(
        id: id,
        name: name,
        policy: policy,
        targetAmountVnd: targetAmountVnd,
        targetDate: targetDate,
        allowNegativeException: allowNegativeException,
        priority: priority,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> archiveEnvelope(int id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      await repo.archiveEnvelope(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final envelopeControllerProvider =
    NotifierProvider<EnvelopeController, AsyncValue<void>>(EnvelopeController.new);
```

---

### 4.4 Presentation Layer Specifications

#### 1. Virtual Funds Screen (`VirtualFundsScreen`)
- **Route**: Mounted in `IndexedStack` at Tab 2 index.
- **Scaffold**:
  - `backgroundColor: AppColors.surfaceSecondary`
  - `AppBar`:
    - `title: Text('Quỹ tiền', style: AppTypography.title)`
    - `actions`:
      - `Semantics(identifier: 'btn_create_envelope', button: true)`: Icon button `Icons.add_circle_outline` opening `EnvelopeFormModal`.
  - `body`: CustomScrollView with `RefreshIndicator` or Slivers:
    1. `SliverToBoxAdapter`: `SummaryHeaderBar` (contains the 3 metric cards, cash buffer info, and over-allocation warning if applicable).
    2. `SliverToBoxAdapter`: `OverAllocationBanner` (rendered when `summary.isOverAllocated`).
    3. `SliverToBoxAdapter`: Quick Actions Bar (`Phân bổ`, `Chuyển quỹ`, `Rút tiền`).
    4. `SliverToBoxAdapter`: `EnvelopeCategorySection` for `PROTECTED` envelopes.
    5. `SliverToBoxAdapter`: `EnvelopeCategorySection` for `FLEXIBLE` envelopes.
    6. `SliverToBoxAdapter`: Bottom scroll clearance padding (`AppSpacing.sp13 = 80px`).

#### 2. Summary Header Bar (`SummaryHeaderBar`)
- **Visual Grid / Row**:
  - Card 1 (`card_summary_liquid`):
    * Label: `"Tài sản khả dụng"`
    * Value: `VndFormatter.format(summary.totalLiquidAssets)` with `FontFeature.tabularFigures()`.
    * Subtext: `"Tiền mặt & Ngân hàng"`
  - Card 2 (`card_summary_reserved`):
    * Label: `"Đã phân bổ vào quỹ"`
    * Value: `VndFormatter.format(summary.totalEnvelopeReserves)` with `FontFeature.tabularFigures()`.
    * Subtext: `"Bảo vệ: ${VndFormatter.format(summary.totalProtectedReserves)}"`
  - Card 3 (`card_summary_available`):
    * Label: `"Sẵn sàng phân bổ"`
    * Value: `VndFormatter.format(summary.availableToAllocate)` with `FontFeature.tabularFigures()`.
    * Background / Border:
      - If `> 0`: `AppColors.surfaceAccentVerdantSecondary` / `borderAccentVerdant`.
      - If `== 0`: `AppColors.surfacePrimary` / `borderSecondary`.
      - If `< 0`: `AppColors.surfaceAccentRubySecondary` / `borderAccentRuby` with Ruby text.
  - Cash Buffer Helper Row:
    * Icon: `Icons.shield_outlined`
    * Text: `"Quỹ dự phòng tiền mặt tối thiểu: ${VndFormatter.format(summary.minimumCashBuffer)}"`
    * Explanation: `available = liquid - reserves - buffer`.

#### 3. Over-Allocation Warning Banner (`OverAllocationBanner`)
- **Semantics**: `Semantics(identifier: 'banner_over_allocation', container: true)`
- **Render Condition**: `summary.isOverAllocated == true` (`availableToAllocate < 0`).
- **Styling**:
  - Container with `BorderRadius.circular(16.0)`, border `AppColors.borderAccentRuby`, background `AppColors.surfaceAccentRubySecondary`.
  - Icon: `Icons.warning_amber_rounded` in `AppColors.iconAccentRuby`.
  - Title: `"Cảnh báo bội phân bổ quỹ"` (`AppTypography.bodyMedium` in `textAccentRubyPrimary`).
  - Description: `"Tổng tiền đã phân bổ vào các quỹ và dự phòng vượt quá tài sản khả dụng thực tế ${VndFormatter.format(summary.overAllocatedAmount)}. Hãy rút tiền từ các quỹ linh hoạt để cân bằng dòng tiền!"`
  - Action button: `"Cân đối ngay"`, opens `ReleaseModal` focused on flexible envelopes.

#### 4. Envelope Category Section (`EnvelopeCategorySection`)
- **Protected Section**:
  - Header: Icon `Icons.lock_outline`, Title: `"Quỹ bảo vệ (Bắt buộc)"`, Badge: `"${envelopes.length} quỹ"`, Subtotal: `VndFormatter.format(subtotal)`.
  - Subtitle: `"Khóa tiền cố định cho chi phí thiết yếu; tự động trừ trong Safe-to-Spend."`
  - Cards: Renders list of `EnvelopeCard` for each protected envelope.
  - Empty state: `"Chưa có quỹ bảo vệ. Nhấn + để tạo quỹ khẩn cấp, tiền thuê nhà, v.v."`
- **Flexible Section**:
  - Header: Icon `Icons.tune_outlined`, Title: `"Quỹ linh hoạt (Tùy chọn)"`, Badge: `"${envelopes.length} quỹ"`, Subtotal: `VndFormatter.format(subtotal)`.
  - Subtitle: `"Dự phòng chi tiêu tùy ý; có thể giải phóng hoặc chuyển quỹ bất kỳ lúc nào."`
  - Cards: Renders list of `EnvelopeCard` for each flexible envelope.
  - Empty state: `"Chưa có quỹ linh hoạt. Nhấn + để tạo quỹ ăn uống, mua sắm, v.v."`

#### 5. Envelope Card (`EnvelopeCard`)
- **Semantics**: `Semantics(identifier: 'card_envelope_${envelope.id}', button: true)`
- **Components**:
  - Top Row:
    * Envelope Icon: `Icons.lock_rounded` (Protected) or `Icons.tune_rounded` (Flexible).
    * Name: `AppTypography.bodyMedium`.
    * Deficit Badge (`badge_deficit_${envelope.id}`): Shown if `envelope.reservedBalanceVnd < 0`. Pill badge in `surfaceAccentRubySecondary` with text `"Thâm hụt"` in `textAccentRubyPrimary`.
    * Target Reached Badge: Shown if `targetAmountVnd != null && reservedBalanceVnd >= targetAmountVnd`. Pill badge in `surfaceAccentVerdantSecondary` with text `"Đạt mục tiêu"`.
  - Amount Row:
    * Text: `VndFormatter.format(envelope.reservedBalanceVnd)` with `AppTypography.headline` and `FontFeature.tabularFigures()`.
    * Color: `AppColors.textAccentRubyPrimary` if negative, else `AppColors.textPrimary`.
  - Target Progress Row (if `envelope.targetAmountVnd != null && envelope.targetAmountVnd! > 0`):
    * `ProgressBar(value: progressRatio, fillColor: isDeficit ? AppColors.fillAccentRubyPrimary : AppColors.fillAccentVerdantPrimary)`.
    * Row below bar:
      - Left: `"${(progressRatio * 100).toInt()}% • Mục tiêu: ${VndFormatter.format(envelope.targetAmountVnd!)}"`
      - Right (if `targetDateMs != null`): `"Hạn: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(envelope.targetDateMs!))}"`
- **OnTap**: Navigates via `Navigator.push` to `EnvelopeDetailScreen(envelopeId: envelope.id)`.

#### 6. Envelope Detail Screen (`EnvelopeDetailScreen`)
- **Semantics**: `Semantics(identifier: 'screen_fund_detail', container: true)`
- **AppBar**:
  - Title: `envelope.name`
  - Actions:
    * `Semantics(identifier: 'btn_edit_envelope')`: opens `EnvelopeFormModal` pre-populated.
    * `Semantics(identifier: 'btn_archive_envelope')`: shows confirmation dialog; archives envelope if confirmed.
- **Hero Balance Card**:
  - Policy Chip: `"Quỹ bảo vệ (Bắt buộc)"` vs `"Quỹ linh hoạt (Tùy chọn)"`.
  - Amount: `VndFormatter.format(envelope.reservedBalanceVnd)` in `AppTypography.largeTitle` with `tabularFigures`.
  - If Deficit: Red warning banner explaining negative balance and showing shortfall.
  - Allow Negative Exception Indicator: `"Cho phép chi tiêu/rút thâm hụt: ${envelope.allowNegativeException ? 'Bật' : 'Tắt'}"`.
- **Target Goal Card** (if target configured):
  - Target amount, current balance, remaining needed (`targetShortfall`).
  - Progress bar and target date.
- **Action Buttons Bar**:
  - `btn_allocate_fund`: Quick action `"Phân bổ"` -> opens `AllocateModal(targetEnvelope: envelope)`.
  - `btn_release_fund`: Quick action `"Rút tiền"` -> opens `ReleaseModal(sourceEnvelope: envelope)`.
  - `btn_transfer_fund`: Quick action `"Chuyển quỹ"` -> opens `TransferModal(sourceEnvelope: envelope)`.
- **Movement History Section**:
  - Header: `"Lịch sử biến động"` with count badge.
  - Streamed list of `EnvelopeMovement` items:
    * Empty state: `"Chưa có biến động nào trong quỹ này."`
    * `MovementHistoryTile` for each movement.

#### 7. Movement History Tile (`MovementHistoryTile`)
- **Semantics**: `Semantics(identifier: 'item_movement_${movement.id}', container: true)`
- **Visuals**:
  - Icon:
    * `ALLOCATE`: `Icons.arrow_downward` (Verdant `#4E886F`).
    * `RELEASE`: `Icons.arrow_upward` (Amber `#FD8240`).
    * `TRANSFER`: `Icons.sync_alt` (Sandstone `#D99650`).
    * `SPEND`: `Icons.shopping_bag_outlined` (Ruby `#F55D3E`).
    * `REFUND_RESTORE`: `Icons.replay` (Verdant `#4E886F`).
    * `REVERSAL`: `Icons.undo` (Charcoal `#65605C`).
  - Title: Context-aware description:
    * `ALLOCATE`: `"Phân bổ từ tiền khả dụng"`
    * `RELEASE`: `"Rút tiền về quỹ khả dụng"`
    * `TRANSFER`: If this is dest: `"Nhận từ quỹ ${sourceName}"`; if this is source: `"Chuyển sang quỹ ${destName}"`.
    * `SPEND`: `"Chi tiêu từ quỹ"`
    * `REFUND_RESTORE`: `"Hoàn tiền vào quỹ"`
    * `REVERSAL`: `"Đảo ngược giao dịch"`
  - Subtitle: Formatted timestamp `HH:mm • dd/MM/yyyy`.
  - Amount:
    * Inflows: `+${VndFormatter.format(movement.amountVnd)}` in `AppColors.textAccentVerdantSecondary`.
    * Outflows: `-${VndFormatter.format(movement.amountVnd)}` in `AppColors.textAccentRubySecondary` or charcoal.
    * Uses `FontFeature.tabularFigures()`.

---

### 4.5 Action Modals Specification

#### 1. Allocate Modal (`AllocateModal`)
- **Semantics**: `Semantics(identifier: 'modal_allocate', container: true)`
- **Header**:
  - Title: `"Phân bổ vào ${envelope.name}"`
  - Subtitle: `"Sẵn sàng phân bổ: ${VndFormatter.format(availableToAllocate)}"`
- **Input & Custom Keypad**:
  - Amount display (`input_amount_display`) formatting real-time integer VND.
  - Keypad buttons `0-9` and backspace `<`.
  - Quick amount chips: `100.000 ₫`, `500.000 ₫`, `1.000.000 ₫`, `"Toàn bộ khả dụng"` (`amount = max(0, availableToAllocate)`).
- **Validation Guard**:
  - If `amount <= 0`: CTA disabled.
  - If `amount > availableToAllocate`:
    * CTA disabled.
    * Inline error text in Ruby red: `"Số tiền phân bổ vượt quá số tiền sẵn sàng phân bổ (${VndFormatter.format(availableToAllocate)})"`.
  - If `availableToAllocate <= 0`:
    * Keypad disabled or warning banner displayed: `"Hiện không có tiền sẵn sàng phân bổ. Vui lòng ghi nhận thu nhập hoặc rút tiền từ quỹ khác."`
- **CTA**: `Semantics(identifier: 'btn_confirm_allocate', button: true)`: `"Xác nhận phân bổ"`.
- **Execution**: Calls `envelopeController.allocate(envelopeId: envelope.id, amountVnd: amount)`.

#### 2. Release Modal (`ReleaseModal`)
- **Semantics**: `Semantics(identifier: 'modal_release', container: true)`
- **Header**:
  - Title: `"Rút tiền từ ${envelope.name}"`
  - Subtitle: `"Số dư quỹ hiện tại: ${VndFormatter.format(envelope.reservedBalanceVnd)}"`
- **Input & Custom Keypad**:
  - Keypad buttons `0-9` and backspace `<`.
  - Quick amount chips: `100.000 ₫`, `500.000 ₫`, `"Tất cả số dư"` (`amount = max(0, envelope.reservedBalanceVnd)`).
- **Validation Guard**:
  - If `amount <= 0`: CTA disabled.
  - If `amount > envelope.reservedBalanceVnd`:
    * If `envelope.allowNegativeException == false`:
      - CTA disabled.
      - Inline error: `"Số tiền rút vượt quá số dư quỹ. Quỹ này không cho phép thâm hụt."`
    * If `envelope.allowNegativeException == true`:
      - Warning prompt displayed: `"Rút số tiền này sẽ khiến quỹ bị âm ${VndFormatter.format(amount - envelope.reservedBalanceVnd)}. Bạn có chắc chắn muốn tiếp tục?"`
      - CTA button style changes to Ruby red with label `"Xác nhận thâm hụt"`.
- **CTA**: `Semantics(identifier: 'btn_confirm_release', button: true)`: `"Xác nhận rút tiền"`.
- **Execution**: Calls `envelopeController.release(envelopeId: envelope.id, amountVnd: amount)`.

#### 3. Transfer Modal (`TransferModal`)
- **Semantics**: `Semantics(identifier: 'modal_transfer', container: true)`
- **Selectors**:
  - Source Envelope Dropdown/Chip-group: defaults to current envelope.
  - Destination Envelope Dropdown/Chip-group: lists all active envelopes where `id != sourceEnvelopeId`. Enforces `source != dest`.
- **Input & Custom Keypad**:
  - Keypad for entering amount in VND.
- **Dynamic Preview**:
  - Box showing:
    * Source: `${source.name}: ${VndFormatter.format(source.reservedBalanceVnd)} ➔ ${VndFormatter.format(source.reservedBalanceVnd - amount)}`
    * Destination: `${dest.name}: ${VndFormatter.format(dest.reservedBalanceVnd)} ➔ ${VndFormatter.format(dest.reservedBalanceVnd + amount)}`
- **Validation Guard**:
  - Enforces `sourceEnvelopeId != destEnvelopeId`.
  - Enforces `amount > 0`.
  - If `amount > source.reservedBalanceVnd && !source.allowNegativeException`: CTA disabled with message `"Số tiền chuyển vượt quá số dư của ${source.name}"`.
- **CTA**: `Semantics(identifier: 'btn_confirm_transfer', button: true)`: `"Xác nhận chuyển quỹ"`.
- **Execution**: Calls `envelopeController.transfer(fromEnvelopeId: sourceId, toEnvelopeId: destId, amountVnd: amount)`.

#### 4. Create / Edit Envelope Modal (`EnvelopeFormModal`)
- **Semantics**: `Semantics(identifier: 'modal_envelope_form', container: true)`
- **Fields**:
  1. Name (`input_envelope_name`): TextField (Vietnamese hint: `"Ví dụ: Quỹ khẩn cấp, Mua laptop"`). Enforces length 1..50 characters.
  2. Policy Selector:
     - `selector_envelope_policy_protected`: Radio card for `"Quỹ bảo vệ (Bắt buộc)"` with lock icon.
     - `selector_envelope_policy_flexible`: Radio card for `"Quỹ linh hoạt (Tùy chọn)"` with tune icon.
  3. Target Amount (`input_envelope_target_amount`): Optional numeric input.
  4. Target Date (`input_envelope_target_date`): Optional date picker (dialog choosing dd/MM/yyyy).
  5. Negative Deficit Toggle (`toggle_allow_negative`): Switch toggle with explanation `"Cho phép chi tiêu hoặc rút tiền vượt quá số dư (số dư âm)"`.
  6. Priority: Number slider / stepper (1..10, default 1).
- **CTA**: `Semantics(identifier: 'btn_save_envelope', button: true)`: `"Tạo quỹ mới"` or `"Lưu thay đổi"`.
- **Execution**: Calls `createEnvelope` or `updateEnvelope`.

---

### 4.6 Complete Semantics Accessibility Map

| Element | Semantics Identifier | Widget Type | Action / Verification |
|---|---|---|---|
| Tab 2 Navigation | `nav_tab_funds` | BottomNavigationBarItem | Navigates to Virtual Funds screen |
| Summary Liquid Assets | `card_summary_liquid` | Card / Container | Displays `total_liquid_assets` |
| Summary Total Reserved | `card_summary_reserved` | Card / Container | Displays `total_envelope_reserves` |
| Summary Available | `card_summary_available` | Card / Container | Displays `available_to_allocate` |
| Over-Allocation Banner | `banner_over_allocation` | Warning Banner | Displayed when `available < 0` |
| Quick Allocate Action | `btn_allocate_fund` | Action Button | Opens Allocate modal |
| Quick Transfer Action | `btn_transfer_fund` | Action Button | Opens Transfer modal |
| Quick Release Action | `btn_release_fund` | Action Button | Opens Release modal |
| Envelope Card | `card_envelope_<id>` | InkWell / Card | Opens EnvelopeDetailScreen |
| Deficit Badge | `badge_deficit_<id>` | Badge | Rendered if `reservedBalance < 0` |
| Create Envelope Button | `btn_create_envelope` | IconButton | Opens EnvelopeFormModal |
| Edit Envelope Button | `btn_edit_envelope` | IconButton | Opens EnvelopeFormModal in edit mode |
| Archive Envelope Button | `btn_archive_envelope` | IconButton | Shows archive confirmation |
| Allocate Modal | `modal_allocate` | BottomSheet | Keypad allocation dialog |
| Release Modal | `modal_release` | BottomSheet | Keypad release dialog |
| Transfer Modal | `modal_transfer` | BottomSheet | Envelope transfer dialog |
| Envelope Form Modal | `modal_envelope_form` | BottomSheet | Create/edit envelope form |
| Name Input | `input_envelope_name` | TextField | Enters envelope name |
| Policy Protected | `selector_envelope_policy_protected` | Radio / Chip | Selects `PROTECTED` |
| Policy Flexible | `selector_envelope_policy_flexible` | Radio / Chip | Selects `FLEXIBLE` |
| Target Amount Input | `input_envelope_target_amount` | TextField / Display | Enters target amount in VND |
| Target Date Input | `input_envelope_target_date` | DatePicker / Button | Picks target deadline |
| Allow Negative Switch | `toggle_allow_negative` | Switch | Toggles negative exception |
| Confirm Allocate | `btn_confirm_allocate` | FilledButton | Submits allocation |
| Confirm Release | `btn_confirm_release` | FilledButton | Submits release |
| Confirm Transfer | `btn_confirm_transfer` | FilledButton | Submits transfer |
| Save Envelope | `btn_save_envelope` | FilledButton | Saves envelope metadata |
| Detail Screen Root | `screen_fund_detail` | Scaffold | Envelope detail root |
| Movement History Row | `item_movement_<id>` | ListTile | Movement history row |

---

## 5. VERIFICATION METHOD & WIDGET TEST PLAN

The implementation must be verified via unit and widget tests in `test/widget/virtual_funds_screen_test.dart` and `test/database/envelope_dao_test.dart`.

### 5.1 The 10 Automated Widget Test Scenarios

1. **Test 1: Metric Summary Cards Rendering**
   - Setup: Seed `10.000.000 ₫` liquid assets, 1 Protected Envelope (`2.000.000 ₫`), 1 Flexible Envelope (`1.000.000 ₫`), minimum buffer = `1.000.000 ₫`.
   - Action: Pump `VirtualFundsScreen`.
   - Invariants:
     * Find `find.bySemanticsIdentifier('card_summary_liquid')` -> contains `"10.000.000 ₫"`.
     * Find `find.bySemanticsIdentifier('card_summary_reserved')` -> contains `"3.000.000 ₫"`.
     * Find `find.bySemanticsIdentifier('card_summary_available')` -> contains `"6.000.000 ₫"` (`10M - 3M - 1M`).
     * `find.bySemanticsIdentifier('banner_over_allocation')` is NOT found.

2. **Test 2: Over-Allocation Warning Banner Display (Scenario 12 Link)**
   - Setup: Liquid assets = `5.000.000 ₫`, Envelopes reserved = `6.000.000 ₫`, Buffer = `1.000.000 ₫`.
   - Calculation: `available = 5M - 6M - 1M = -2.000.000 ₫`.
   - Invariants:
     * Find `find.bySemanticsIdentifier('card_summary_available')` -> contains `"-2.000.000 ₫"`.
     * Find `find.bySemanticsIdentifier('banner_over_allocation')` -> finds 1 widget.
     * Text in banner contains `"2.000.000 ₫"`.

3. **Test 3: Categorized Section Partitioning**
   - Setup: 2 envelopes with `policy: 'PROTECTED'`, 2 envelopes with `policy: 'FLEXIBLE'`.
   - Action: Pump `VirtualFundsScreen`.
   - Invariants:
     * Section "Quỹ bảo vệ" lists the 2 protected envelopes.
     * Section "Quỹ linh hoạt" lists the 2 flexible envelopes.
     * Correct subtotals displayed for both sections.

4. **Test 4: Envelope Card Target Progress & Deficit Badge**
   - Setup:
     * Envelope 1: `reserved: 5.000.000 ₫`, `target: 10.000.000 ₫` -> progress = 50%.
     * Envelope 2: `reserved: -500.000 ₫`, `allowNegativeException: true`.
   - Invariants:
     * Card 1 displays `5.000.000 ₫` and progress text `"50%"`.
     * Card 2 displays `find.bySemanticsIdentifier('badge_deficit_2')` with text `"Thâm hụt"`, and balance `"-500.000 ₫"`.

5. **Test 5: Allocate Modal Guard Enforces `amount <= available_to_allocate`**
   - Setup: `available_to_allocate = 1.000.000 ₫`. Open Allocate Modal for Envelope 1.
   - Action:
     * Enter `1` `2` `0` `0` `0` `0` `0` (`1.200.000 ₫`) via keypad.
   - Invariants:
     * Confirm button `find.bySemanticsIdentifier('btn_confirm_allocate')` is disabled (`tester.widget<FilledButton>(...).onPressed == null`).
     * Error banner displays `"Số tiền phân bổ vượt quá số tiền sẵn sàng phân bổ (1.000.000 ₫)"`.
     * Tap backspace 2 times -> amount becomes `12.000 ₫` -> confirm button becomes enabled.

6. **Test 6: Successful Allocation Reactive Update (Scenario 5 Link)**
   - Setup: `available_to_allocate = 28.900.000 ₫`, Envelope reserve = `0 ₫`.
   - Action: Allocate `1.000.000 ₫` to Envelope.
   - Invariants:
     * Envelope reserved updates to `1.000.000 ₫`.
     * `card_summary_reserved` increases by `1.000.000 ₫`.
     * `card_summary_available` decreases by `1.000.000 ₫`.
     * Zero journal postings created.

7. **Test 7: Release Modal Guard Against Deficit**
   - Setup: Envelope has `reserved: 500.000 ₫`, `allowNegativeException: false`.
   - Action: Open Release modal, enter `600.000 ₫`.
   - Invariants:
     * Confirm button is disabled with error message `"Số tiền rút vượt quá số dư quỹ"`.
   - Change: Open Release modal on envelope with `allowNegativeException: true`.
   - Invariants:
     * Confirm button is enabled with label `"Xác nhận thâm hụt"`.

8. **Test 8: Transfer Modal Distinct Source & Destination Enforcement**
   - Setup: Envelopes A (`2.000.000 ₫`) and B (`0 ₫`). Open Transfer modal with Source A.
   - Action:
     * Destination selector excludes Envelope A (`source != dest`).
     * Enter `1.000.000 ₫` and tap confirm.
   - Invariants:
     * Envelope A reserved becomes `1.000.000 ₫`.
     * Envelope B reserved becomes `1.000.000 ₫`.
     * `total_envelope_reserves` and `available_to_allocate` remain completely unchanged.

9. **Test 9: Create Envelope Modal Form Validation & Persistence**
   - Action: Tap `btn_create_envelope`, enter name `"Quỹ Du Lịch"`, select `PROTECTED`, target `"15.000.000 ₫"`, tap `btn_save_envelope`.
   - Invariants:
     * Modal dismisses.
     * New card `card_envelope_<id>` appears in the `PROTECTED` section with balance `0 ₫` and target `15.000.000 ₫`.

10. **Test 10: Envelope Detail Screen Movement History Log**
    - Setup: Envelope with 1 `ALLOCATE` (`1.000.000 ₫`), 1 `SPEND` (`200.000 ₫`), and 1 `REFUND_RESTORE` (`50.000 ₫`).
    - Action: Navigate to `EnvelopeDetailScreen`.
    - Invariants:
      * Balance displays `850.000 ₫`.
      * History displays 3 `item_movement_<id>` tiles:
        - `ALLOCATE`: `+1.000.000 ₫` (Verdant text)
        - `SPEND`: `-200.000 ₫` (Ruby text)
        - `REFUND_RESTORE`: `+50.000 ₫` (Verdant text)

### 5.2 Test Execution Commands

```bash
# Run unit and database tests
flutter test test/database/adversarial_ledger_envelope_test.dart

# Run widget tests
flutter test test/widget/virtual_funds_screen_test.dart

# Run formatting and analysis
dart format --output=none --set-exit-if-changed .
flutter analyze
```

---

## 6. HANDOFF STATUS
- **Status**: Complete & Ready for Implementation
- **Deliverable**: Architectural blueprint, Riverpod provider specifications, UI widget layout, Action modals, Semantics map, and 10 widget test scenarios.
