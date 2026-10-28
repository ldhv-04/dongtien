// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LedgerAccountsTable extends LedgerAccounts
    with TableInfo<$LedgerAccountsTable, LedgerAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isLiquidMeta =
      const VerificationMeta('isLiquid');
  @override
  late final GeneratedColumn<bool> isLiquid = GeneratedColumn<bool>(
      'is_liquid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_liquid" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _creditLimitMeta =
      const VerificationMeta('creditLimit');
  @override
  late final GeneratedColumn<int> creditLimit = GeneratedColumn<int>(
      'credit_limit', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, kind, isLiquid, creditLimit, isArchived, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_accounts';
  @override
  VerificationContext validateIntegrity(Insertable<LedgerAccount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('is_liquid')) {
      context.handle(_isLiquidMeta,
          isLiquid.isAcceptableOrUnknown(data['is_liquid']!, _isLiquidMeta));
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
          _creditLimitMeta,
          creditLimit.isAcceptableOrUnknown(
              data['credit_limit']!, _creditLimitMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerAccount(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      isLiquid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_liquid'])!,
      creditLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}credit_limit'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LedgerAccountsTable createAlias(String alias) {
    return $LedgerAccountsTable(attachedDatabase, alias);
  }
}

class LedgerAccount extends DataClass implements Insertable<LedgerAccount> {
  final int id;
  final String name;
  final String kind;
  final bool isLiquid;
  final int creditLimit;
  final bool isArchived;
  final int createdAt;
  const LedgerAccount(
      {required this.id,
      required this.name,
      required this.kind,
      required this.isLiquid,
      required this.creditLimit,
      required this.isArchived,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['is_liquid'] = Variable<bool>(isLiquid);
    map['credit_limit'] = Variable<int>(creditLimit);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  LedgerAccountsCompanion toCompanion(bool nullToAbsent) {
    return LedgerAccountsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      isLiquid: Value(isLiquid),
      creditLimit: Value(creditLimit),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
    );
  }

  factory LedgerAccount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerAccount(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      isLiquid: serializer.fromJson<bool>(json['isLiquid']),
      creditLimit: serializer.fromJson<int>(json['creditLimit']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'isLiquid': serializer.toJson<bool>(isLiquid),
      'creditLimit': serializer.toJson<int>(creditLimit),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  LedgerAccount copyWith(
          {int? id,
          String? name,
          String? kind,
          bool? isLiquid,
          int? creditLimit,
          bool? isArchived,
          int? createdAt}) =>
      LedgerAccount(
        id: id ?? this.id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        isLiquid: isLiquid ?? this.isLiquid,
        creditLimit: creditLimit ?? this.creditLimit,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
      );
  LedgerAccount copyWithCompanion(LedgerAccountsCompanion data) {
    return LedgerAccount(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      isLiquid: data.isLiquid.present ? data.isLiquid.value : this.isLiquid,
      creditLimit:
          data.creditLimit.present ? data.creditLimit.value : this.creditLimit,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerAccount(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('isLiquid: $isLiquid, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, kind, isLiquid, creditLimit, isArchived, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerAccount &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.isLiquid == this.isLiquid &&
          other.creditLimit == this.creditLimit &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt);
}

class LedgerAccountsCompanion extends UpdateCompanion<LedgerAccount> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<bool> isLiquid;
  final Value<int> creditLimit;
  final Value<bool> isArchived;
  final Value<int> createdAt;
  const LedgerAccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.isLiquid = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LedgerAccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String kind,
    this.isLiquid = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.isArchived = const Value.absent(),
    required int createdAt,
  })  : name = Value(name),
        kind = Value(kind),
        createdAt = Value(createdAt);
  static Insertable<LedgerAccount> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<bool>? isLiquid,
    Expression<int>? creditLimit,
    Expression<bool>? isArchived,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (isLiquid != null) 'is_liquid': isLiquid,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LedgerAccountsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? kind,
      Value<bool>? isLiquid,
      Value<int>? creditLimit,
      Value<bool>? isArchived,
      Value<int>? createdAt}) {
    return LedgerAccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      isLiquid: isLiquid ?? this.isLiquid,
      creditLimit: creditLimit ?? this.creditLimit,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (isLiquid.present) {
      map['is_liquid'] = Variable<bool>(isLiquid.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<int>(creditLimit.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerAccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('isLiquid: $isLiquid, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ledgerAccountIdMeta =
      const VerificationMeta('ledgerAccountId');
  @override
  late final GeneratedColumn<int> ledgerAccountId = GeneratedColumn<int>(
      'ledger_account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES ledger_accounts (id) ON DELETE RESTRICT'));
  static const VerificationMeta _iconCodeMeta =
      const VerificationMeta('iconCode');
  @override
  late final GeneratedColumn<int> iconCode = GeneratedColumn<int>(
      'icon_code', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        kind,
        ledgerAccountId,
        iconCode,
        colorHex,
        isDefault,
        isArchived
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ledger_account_id')) {
      context.handle(
          _ledgerAccountIdMeta,
          ledgerAccountId.isAcceptableOrUnknown(
              data['ledger_account_id']!, _ledgerAccountIdMeta));
    } else if (isInserting) {
      context.missing(_ledgerAccountIdMeta);
    }
    if (data.containsKey('icon_code')) {
      context.handle(_iconCodeMeta,
          iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta));
    } else if (isInserting) {
      context.missing(_iconCodeMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      ledgerAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ledger_account_id'])!,
      iconCode: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}icon_code'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final String kind;
  final int ledgerAccountId;
  final int iconCode;
  final String colorHex;
  final bool isDefault;
  final bool isArchived;
  const Category(
      {required this.id,
      required this.name,
      required this.kind,
      required this.ledgerAccountId,
      required this.iconCode,
      required this.colorHex,
      required this.isDefault,
      required this.isArchived});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['ledger_account_id'] = Variable<int>(ledgerAccountId);
    map['icon_code'] = Variable<int>(iconCode);
    map['color_hex'] = Variable<String>(colorHex);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_archived'] = Variable<bool>(isArchived);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      ledgerAccountId: Value(ledgerAccountId),
      iconCode: Value(iconCode),
      colorHex: Value(colorHex),
      isDefault: Value(isDefault),
      isArchived: Value(isArchived),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      ledgerAccountId: serializer.fromJson<int>(json['ledgerAccountId']),
      iconCode: serializer.fromJson<int>(json['iconCode']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'ledgerAccountId': serializer.toJson<int>(ledgerAccountId),
      'iconCode': serializer.toJson<int>(iconCode),
      'colorHex': serializer.toJson<String>(colorHex),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isArchived': serializer.toJson<bool>(isArchived),
    };
  }

  Category copyWith(
          {int? id,
          String? name,
          String? kind,
          int? ledgerAccountId,
          int? iconCode,
          String? colorHex,
          bool? isDefault,
          bool? isArchived}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        ledgerAccountId: ledgerAccountId ?? this.ledgerAccountId,
        iconCode: iconCode ?? this.iconCode,
        colorHex: colorHex ?? this.colorHex,
        isDefault: isDefault ?? this.isDefault,
        isArchived: isArchived ?? this.isArchived,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      ledgerAccountId: data.ledgerAccountId.present
          ? data.ledgerAccountId.value
          : this.ledgerAccountId,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('ledgerAccountId: $ledgerAccountId, ')
          ..write('iconCode: $iconCode, ')
          ..write('colorHex: $colorHex, ')
          ..write('isDefault: $isDefault, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, kind, ledgerAccountId, iconCode,
      colorHex, isDefault, isArchived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.ledgerAccountId == this.ledgerAccountId &&
          other.iconCode == this.iconCode &&
          other.colorHex == this.colorHex &&
          other.isDefault == this.isDefault &&
          other.isArchived == this.isArchived);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<int> ledgerAccountId;
  final Value<int> iconCode;
  final Value<String> colorHex;
  final Value<bool> isDefault;
  final Value<bool> isArchived;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.ledgerAccountId = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isArchived = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String kind,
    required int ledgerAccountId,
    required int iconCode,
    required String colorHex,
    this.isDefault = const Value.absent(),
    this.isArchived = const Value.absent(),
  })  : name = Value(name),
        kind = Value(kind),
        ledgerAccountId = Value(ledgerAccountId),
        iconCode = Value(iconCode),
        colorHex = Value(colorHex);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? ledgerAccountId,
    Expression<int>? iconCode,
    Expression<String>? colorHex,
    Expression<bool>? isDefault,
    Expression<bool>? isArchived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (ledgerAccountId != null) 'ledger_account_id': ledgerAccountId,
      if (iconCode != null) 'icon_code': iconCode,
      if (colorHex != null) 'color_hex': colorHex,
      if (isDefault != null) 'is_default': isDefault,
      if (isArchived != null) 'is_archived': isArchived,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? kind,
      Value<int>? ledgerAccountId,
      Value<int>? iconCode,
      Value<String>? colorHex,
      Value<bool>? isDefault,
      Value<bool>? isArchived}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      ledgerAccountId: ledgerAccountId ?? this.ledgerAccountId,
      iconCode: iconCode ?? this.iconCode,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (ledgerAccountId.present) {
      map['ledger_account_id'] = Variable<int>(ledgerAccountId.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<int>(iconCode.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('ledgerAccountId: $ledgerAccountId, ')
          ..write('iconCode: $iconCode, ')
          ..write('colorHex: $colorHex, ')
          ..write('isDefault: $isDefault, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }
}

class $JournalTransactionsTable extends JournalTransactions
    with TableInfo<$JournalTransactionsTable, JournalTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _txTypeMeta = const VerificationMeta('txType');
  @override
  late final GeneratedColumn<String> txType = GeneratedColumn<String>(
      'tx_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('POSTED'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _idempotencyKeyMeta =
      const VerificationMeta('idempotencyKey');
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
      'idempotency_key', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _reversesTxIdMeta =
      const VerificationMeta('reversesTxId');
  @override
  late final GeneratedColumn<int> reversesTxId = GeneratedColumn<int>(
      'reverses_tx_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES journal_transactions (id) ON DELETE SET NULL'));
  static const VerificationMeta _replacedByTxIdMeta =
      const VerificationMeta('replacedByTxId');
  @override
  late final GeneratedColumn<int> replacedByTxId = GeneratedColumn<int>(
      'replaced_by_tx_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES journal_transactions (id) ON DELETE SET NULL'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        txType,
        status,
        description,
        occurredAt,
        createdAt,
        idempotencyKey,
        reversesTxId,
        replacedByTxId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_transactions';
  @override
  VerificationContext validateIntegrity(Insertable<JournalTransaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tx_type')) {
      context.handle(_txTypeMeta,
          txType.isAcceptableOrUnknown(data['tx_type']!, _txTypeMeta));
    } else if (isInserting) {
      context.missing(_txTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
          _idempotencyKeyMeta,
          idempotencyKey.isAcceptableOrUnknown(
              data['idempotency_key']!, _idempotencyKeyMeta));
    }
    if (data.containsKey('reverses_tx_id')) {
      context.handle(
          _reversesTxIdMeta,
          reversesTxId.isAcceptableOrUnknown(
              data['reverses_tx_id']!, _reversesTxIdMeta));
    }
    if (data.containsKey('replaced_by_tx_id')) {
      context.handle(
          _replacedByTxIdMeta,
          replacedByTxId.isAcceptableOrUnknown(
              data['replaced_by_tx_id']!, _replacedByTxIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalTransaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      txType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tx_type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}occurred_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      idempotencyKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}idempotency_key']),
      reversesTxId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reverses_tx_id']),
      replacedByTxId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}replaced_by_tx_id']),
    );
  }

  @override
  $JournalTransactionsTable createAlias(String alias) {
    return $JournalTransactionsTable(attachedDatabase, alias);
  }
}

class JournalTransaction extends DataClass
    implements Insertable<JournalTransaction> {
  final int id;
  final String txType;
  final String status;
  final String description;
  final int occurredAt;
  final int createdAt;
  final String? idempotencyKey;
  final int? reversesTxId;
  final int? replacedByTxId;
  const JournalTransaction(
      {required this.id,
      required this.txType,
      required this.status,
      required this.description,
      required this.occurredAt,
      required this.createdAt,
      this.idempotencyKey,
      this.reversesTxId,
      this.replacedByTxId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tx_type'] = Variable<String>(txType);
    map['status'] = Variable<String>(status);
    map['description'] = Variable<String>(description);
    map['occurred_at'] = Variable<int>(occurredAt);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    if (!nullToAbsent || reversesTxId != null) {
      map['reverses_tx_id'] = Variable<int>(reversesTxId);
    }
    if (!nullToAbsent || replacedByTxId != null) {
      map['replaced_by_tx_id'] = Variable<int>(replacedByTxId);
    }
    return map;
  }

  JournalTransactionsCompanion toCompanion(bool nullToAbsent) {
    return JournalTransactionsCompanion(
      id: Value(id),
      txType: Value(txType),
      status: Value(status),
      description: Value(description),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      reversesTxId: reversesTxId == null && nullToAbsent
          ? const Value.absent()
          : Value(reversesTxId),
      replacedByTxId: replacedByTxId == null && nullToAbsent
          ? const Value.absent()
          : Value(replacedByTxId),
    );
  }

  factory JournalTransaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalTransaction(
      id: serializer.fromJson<int>(json['id']),
      txType: serializer.fromJson<String>(json['txType']),
      status: serializer.fromJson<String>(json['status']),
      description: serializer.fromJson<String>(json['description']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      reversesTxId: serializer.fromJson<int?>(json['reversesTxId']),
      replacedByTxId: serializer.fromJson<int?>(json['replacedByTxId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'txType': serializer.toJson<String>(txType),
      'status': serializer.toJson<String>(status),
      'description': serializer.toJson<String>(description),
      'occurredAt': serializer.toJson<int>(occurredAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'reversesTxId': serializer.toJson<int?>(reversesTxId),
      'replacedByTxId': serializer.toJson<int?>(replacedByTxId),
    };
  }

  JournalTransaction copyWith(
          {int? id,
          String? txType,
          String? status,
          String? description,
          int? occurredAt,
          int? createdAt,
          Value<String?> idempotencyKey = const Value.absent(),
          Value<int?> reversesTxId = const Value.absent(),
          Value<int?> replacedByTxId = const Value.absent()}) =>
      JournalTransaction(
        id: id ?? this.id,
        txType: txType ?? this.txType,
        status: status ?? this.status,
        description: description ?? this.description,
        occurredAt: occurredAt ?? this.occurredAt,
        createdAt: createdAt ?? this.createdAt,
        idempotencyKey:
            idempotencyKey.present ? idempotencyKey.value : this.idempotencyKey,
        reversesTxId:
            reversesTxId.present ? reversesTxId.value : this.reversesTxId,
        replacedByTxId:
            replacedByTxId.present ? replacedByTxId.value : this.replacedByTxId,
      );
  JournalTransaction copyWithCompanion(JournalTransactionsCompanion data) {
    return JournalTransaction(
      id: data.id.present ? data.id.value : this.id,
      txType: data.txType.present ? data.txType.value : this.txType,
      status: data.status.present ? data.status.value : this.status,
      description:
          data.description.present ? data.description.value : this.description,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      reversesTxId: data.reversesTxId.present
          ? data.reversesTxId.value
          : this.reversesTxId,
      replacedByTxId: data.replacedByTxId.present
          ? data.replacedByTxId.value
          : this.replacedByTxId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalTransaction(')
          ..write('id: $id, ')
          ..write('txType: $txType, ')
          ..write('status: $status, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('reversesTxId: $reversesTxId, ')
          ..write('replacedByTxId: $replacedByTxId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, txType, status, description, occurredAt,
      createdAt, idempotencyKey, reversesTxId, replacedByTxId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalTransaction &&
          other.id == this.id &&
          other.txType == this.txType &&
          other.status == this.status &&
          other.description == this.description &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt &&
          other.idempotencyKey == this.idempotencyKey &&
          other.reversesTxId == this.reversesTxId &&
          other.replacedByTxId == this.replacedByTxId);
}

class JournalTransactionsCompanion extends UpdateCompanion<JournalTransaction> {
  final Value<int> id;
  final Value<String> txType;
  final Value<String> status;
  final Value<String> description;
  final Value<int> occurredAt;
  final Value<int> createdAt;
  final Value<String?> idempotencyKey;
  final Value<int?> reversesTxId;
  final Value<int?> replacedByTxId;
  const JournalTransactionsCompanion({
    this.id = const Value.absent(),
    this.txType = const Value.absent(),
    this.status = const Value.absent(),
    this.description = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.reversesTxId = const Value.absent(),
    this.replacedByTxId = const Value.absent(),
  });
  JournalTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String txType,
    this.status = const Value.absent(),
    this.description = const Value.absent(),
    required int occurredAt,
    required int createdAt,
    this.idempotencyKey = const Value.absent(),
    this.reversesTxId = const Value.absent(),
    this.replacedByTxId = const Value.absent(),
  })  : txType = Value(txType),
        occurredAt = Value(occurredAt),
        createdAt = Value(createdAt);
  static Insertable<JournalTransaction> custom({
    Expression<int>? id,
    Expression<String>? txType,
    Expression<String>? status,
    Expression<String>? description,
    Expression<int>? occurredAt,
    Expression<int>? createdAt,
    Expression<String>? idempotencyKey,
    Expression<int>? reversesTxId,
    Expression<int>? replacedByTxId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (txType != null) 'tx_type': txType,
      if (status != null) 'status': status,
      if (description != null) 'description': description,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (reversesTxId != null) 'reverses_tx_id': reversesTxId,
      if (replacedByTxId != null) 'replaced_by_tx_id': replacedByTxId,
    });
  }

  JournalTransactionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? txType,
      Value<String>? status,
      Value<String>? description,
      Value<int>? occurredAt,
      Value<int>? createdAt,
      Value<String?>? idempotencyKey,
      Value<int?>? reversesTxId,
      Value<int?>? replacedByTxId}) {
    return JournalTransactionsCompanion(
      id: id ?? this.id,
      txType: txType ?? this.txType,
      status: status ?? this.status,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      reversesTxId: reversesTxId ?? this.reversesTxId,
      replacedByTxId: replacedByTxId ?? this.replacedByTxId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (txType.present) {
      map['tx_type'] = Variable<String>(txType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (reversesTxId.present) {
      map['reverses_tx_id'] = Variable<int>(reversesTxId.value);
    }
    if (replacedByTxId.present) {
      map['replaced_by_tx_id'] = Variable<int>(replacedByTxId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('txType: $txType, ')
          ..write('status: $status, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('reversesTxId: $reversesTxId, ')
          ..write('replacedByTxId: $replacedByTxId')
          ..write(')'))
        .toString();
  }
}

class $EnvelopesTable extends Envelopes
    with TableInfo<$EnvelopesTable, Envelope> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvelopesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _policyMeta = const VerificationMeta('policy');
  @override
  late final GeneratedColumn<String> policy = GeneratedColumn<String>(
      'policy', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reservedBalanceVndMeta =
      const VerificationMeta('reservedBalanceVnd');
  @override
  late final GeneratedColumn<int> reservedBalanceVnd = GeneratedColumn<int>(
      'reserved_balance_vnd', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _allowNegativeExceptionMeta =
      const VerificationMeta('allowNegativeException');
  @override
  late final GeneratedColumn<bool> allowNegativeException =
      GeneratedColumn<bool>('allow_negative_exception', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("allow_negative_exception" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _targetAmountVndMeta =
      const VerificationMeta('targetAmountVnd');
  @override
  late final GeneratedColumn<int> targetAmountVnd = GeneratedColumn<int>(
      'target_amount_vnd', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _targetDateMsMeta =
      const VerificationMeta('targetDateMs');
  @override
  late final GeneratedColumn<int> targetDateMs = GeneratedColumn<int>(
      'target_date_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _periodLimitVndMeta =
      const VerificationMeta('periodLimitVnd');
  @override
  late final GeneratedColumn<int> periodLimitVnd = GeneratedColumn<int>(
      'period_limit_vnd', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _rolloverEnabledMeta =
      const VerificationMeta('rolloverEnabled');
  @override
  late final GeneratedColumn<bool> rolloverEnabled = GeneratedColumn<bool>(
      'rollover_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("rollover_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        policy,
        reservedBalanceVnd,
        allowNegativeException,
        targetAmountVnd,
        targetDateMs,
        periodLimitVnd,
        rolloverEnabled,
        priority,
        isArchived
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'envelopes';
  @override
  VerificationContext validateIntegrity(Insertable<Envelope> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('policy')) {
      context.handle(_policyMeta,
          policy.isAcceptableOrUnknown(data['policy']!, _policyMeta));
    } else if (isInserting) {
      context.missing(_policyMeta);
    }
    if (data.containsKey('reserved_balance_vnd')) {
      context.handle(
          _reservedBalanceVndMeta,
          reservedBalanceVnd.isAcceptableOrUnknown(
              data['reserved_balance_vnd']!, _reservedBalanceVndMeta));
    }
    if (data.containsKey('allow_negative_exception')) {
      context.handle(
          _allowNegativeExceptionMeta,
          allowNegativeException.isAcceptableOrUnknown(
              data['allow_negative_exception']!, _allowNegativeExceptionMeta));
    }
    if (data.containsKey('target_amount_vnd')) {
      context.handle(
          _targetAmountVndMeta,
          targetAmountVnd.isAcceptableOrUnknown(
              data['target_amount_vnd']!, _targetAmountVndMeta));
    }
    if (data.containsKey('target_date_ms')) {
      context.handle(
          _targetDateMsMeta,
          targetDateMs.isAcceptableOrUnknown(
              data['target_date_ms']!, _targetDateMsMeta));
    }
    if (data.containsKey('period_limit_vnd')) {
      context.handle(
          _periodLimitVndMeta,
          periodLimitVnd.isAcceptableOrUnknown(
              data['period_limit_vnd']!, _periodLimitVndMeta));
    }
    if (data.containsKey('rollover_enabled')) {
      context.handle(
          _rolloverEnabledMeta,
          rolloverEnabled.isAcceptableOrUnknown(
              data['rollover_enabled']!, _rolloverEnabledMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Envelope map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Envelope(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      policy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}policy'])!,
      reservedBalanceVnd: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}reserved_balance_vnd'])!,
      allowNegativeException: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}allow_negative_exception'])!,
      targetAmountVnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_amount_vnd']),
      targetDateMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_date_ms']),
      periodLimitVnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period_limit_vnd']),
      rolloverEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}rollover_enabled'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
    );
  }

  @override
  $EnvelopesTable createAlias(String alias) {
    return $EnvelopesTable(attachedDatabase, alias);
  }
}

class Envelope extends DataClass implements Insertable<Envelope> {
  final int id;
  final String name;
  final String policy;
  final int reservedBalanceVnd;
  final bool allowNegativeException;
  final int? targetAmountVnd;
  final int? targetDateMs;
  final int? periodLimitVnd;
  final bool rolloverEnabled;
  final int priority;
  final bool isArchived;
  const Envelope(
      {required this.id,
      required this.name,
      required this.policy,
      required this.reservedBalanceVnd,
      required this.allowNegativeException,
      this.targetAmountVnd,
      this.targetDateMs,
      this.periodLimitVnd,
      required this.rolloverEnabled,
      required this.priority,
      required this.isArchived});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['policy'] = Variable<String>(policy);
    map['reserved_balance_vnd'] = Variable<int>(reservedBalanceVnd);
    map['allow_negative_exception'] = Variable<bool>(allowNegativeException);
    if (!nullToAbsent || targetAmountVnd != null) {
      map['target_amount_vnd'] = Variable<int>(targetAmountVnd);
    }
    if (!nullToAbsent || targetDateMs != null) {
      map['target_date_ms'] = Variable<int>(targetDateMs);
    }
    if (!nullToAbsent || periodLimitVnd != null) {
      map['period_limit_vnd'] = Variable<int>(periodLimitVnd);
    }
    map['rollover_enabled'] = Variable<bool>(rolloverEnabled);
    map['priority'] = Variable<int>(priority);
    map['is_archived'] = Variable<bool>(isArchived);
    return map;
  }

  EnvelopesCompanion toCompanion(bool nullToAbsent) {
    return EnvelopesCompanion(
      id: Value(id),
      name: Value(name),
      policy: Value(policy),
      reservedBalanceVnd: Value(reservedBalanceVnd),
      allowNegativeException: Value(allowNegativeException),
      targetAmountVnd: targetAmountVnd == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAmountVnd),
      targetDateMs: targetDateMs == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDateMs),
      periodLimitVnd: periodLimitVnd == null && nullToAbsent
          ? const Value.absent()
          : Value(periodLimitVnd),
      rolloverEnabled: Value(rolloverEnabled),
      priority: Value(priority),
      isArchived: Value(isArchived),
    );
  }

  factory Envelope.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Envelope(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      policy: serializer.fromJson<String>(json['policy']),
      reservedBalanceVnd: serializer.fromJson<int>(json['reservedBalanceVnd']),
      allowNegativeException:
          serializer.fromJson<bool>(json['allowNegativeException']),
      targetAmountVnd: serializer.fromJson<int?>(json['targetAmountVnd']),
      targetDateMs: serializer.fromJson<int?>(json['targetDateMs']),
      periodLimitVnd: serializer.fromJson<int?>(json['periodLimitVnd']),
      rolloverEnabled: serializer.fromJson<bool>(json['rolloverEnabled']),
      priority: serializer.fromJson<int>(json['priority']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'policy': serializer.toJson<String>(policy),
      'reservedBalanceVnd': serializer.toJson<int>(reservedBalanceVnd),
      'allowNegativeException': serializer.toJson<bool>(allowNegativeException),
      'targetAmountVnd': serializer.toJson<int?>(targetAmountVnd),
      'targetDateMs': serializer.toJson<int?>(targetDateMs),
      'periodLimitVnd': serializer.toJson<int?>(periodLimitVnd),
      'rolloverEnabled': serializer.toJson<bool>(rolloverEnabled),
      'priority': serializer.toJson<int>(priority),
      'isArchived': serializer.toJson<bool>(isArchived),
    };
  }

  Envelope copyWith(
          {int? id,
          String? name,
          String? policy,
          int? reservedBalanceVnd,
          bool? allowNegativeException,
          Value<int?> targetAmountVnd = const Value.absent(),
          Value<int?> targetDateMs = const Value.absent(),
          Value<int?> periodLimitVnd = const Value.absent(),
          bool? rolloverEnabled,
          int? priority,
          bool? isArchived}) =>
      Envelope(
        id: id ?? this.id,
        name: name ?? this.name,
        policy: policy ?? this.policy,
        reservedBalanceVnd: reservedBalanceVnd ?? this.reservedBalanceVnd,
        allowNegativeException:
            allowNegativeException ?? this.allowNegativeException,
        targetAmountVnd: targetAmountVnd.present
            ? targetAmountVnd.value
            : this.targetAmountVnd,
        targetDateMs:
            targetDateMs.present ? targetDateMs.value : this.targetDateMs,
        periodLimitVnd:
            periodLimitVnd.present ? periodLimitVnd.value : this.periodLimitVnd,
        rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
        priority: priority ?? this.priority,
        isArchived: isArchived ?? this.isArchived,
      );
  Envelope copyWithCompanion(EnvelopesCompanion data) {
    return Envelope(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      policy: data.policy.present ? data.policy.value : this.policy,
      reservedBalanceVnd: data.reservedBalanceVnd.present
          ? data.reservedBalanceVnd.value
          : this.reservedBalanceVnd,
      allowNegativeException: data.allowNegativeException.present
          ? data.allowNegativeException.value
          : this.allowNegativeException,
      targetAmountVnd: data.targetAmountVnd.present
          ? data.targetAmountVnd.value
          : this.targetAmountVnd,
      targetDateMs: data.targetDateMs.present
          ? data.targetDateMs.value
          : this.targetDateMs,
      periodLimitVnd: data.periodLimitVnd.present
          ? data.periodLimitVnd.value
          : this.periodLimitVnd,
      rolloverEnabled: data.rolloverEnabled.present
          ? data.rolloverEnabled.value
          : this.rolloverEnabled,
      priority: data.priority.present ? data.priority.value : this.priority,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Envelope(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('policy: $policy, ')
          ..write('reservedBalanceVnd: $reservedBalanceVnd, ')
          ..write('allowNegativeException: $allowNegativeException, ')
          ..write('targetAmountVnd: $targetAmountVnd, ')
          ..write('targetDateMs: $targetDateMs, ')
          ..write('periodLimitVnd: $periodLimitVnd, ')
          ..write('rolloverEnabled: $rolloverEnabled, ')
          ..write('priority: $priority, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      policy,
      reservedBalanceVnd,
      allowNegativeException,
      targetAmountVnd,
      targetDateMs,
      periodLimitVnd,
      rolloverEnabled,
      priority,
      isArchived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Envelope &&
          other.id == this.id &&
          other.name == this.name &&
          other.policy == this.policy &&
          other.reservedBalanceVnd == this.reservedBalanceVnd &&
          other.allowNegativeException == this.allowNegativeException &&
          other.targetAmountVnd == this.targetAmountVnd &&
          other.targetDateMs == this.targetDateMs &&
          other.periodLimitVnd == this.periodLimitVnd &&
          other.rolloverEnabled == this.rolloverEnabled &&
          other.priority == this.priority &&
          other.isArchived == this.isArchived);
}

class EnvelopesCompanion extends UpdateCompanion<Envelope> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> policy;
  final Value<int> reservedBalanceVnd;
  final Value<bool> allowNegativeException;
  final Value<int?> targetAmountVnd;
  final Value<int?> targetDateMs;
  final Value<int?> periodLimitVnd;
  final Value<bool> rolloverEnabled;
  final Value<int> priority;
  final Value<bool> isArchived;
  const EnvelopesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.policy = const Value.absent(),
    this.reservedBalanceVnd = const Value.absent(),
    this.allowNegativeException = const Value.absent(),
    this.targetAmountVnd = const Value.absent(),
    this.targetDateMs = const Value.absent(),
    this.periodLimitVnd = const Value.absent(),
    this.rolloverEnabled = const Value.absent(),
    this.priority = const Value.absent(),
    this.isArchived = const Value.absent(),
  });
  EnvelopesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String policy,
    this.reservedBalanceVnd = const Value.absent(),
    this.allowNegativeException = const Value.absent(),
    this.targetAmountVnd = const Value.absent(),
    this.targetDateMs = const Value.absent(),
    this.periodLimitVnd = const Value.absent(),
    this.rolloverEnabled = const Value.absent(),
    this.priority = const Value.absent(),
    this.isArchived = const Value.absent(),
  })  : name = Value(name),
        policy = Value(policy);
  static Insertable<Envelope> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? policy,
    Expression<int>? reservedBalanceVnd,
    Expression<bool>? allowNegativeException,
    Expression<int>? targetAmountVnd,
    Expression<int>? targetDateMs,
    Expression<int>? periodLimitVnd,
    Expression<bool>? rolloverEnabled,
    Expression<int>? priority,
    Expression<bool>? isArchived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (policy != null) 'policy': policy,
      if (reservedBalanceVnd != null)
        'reserved_balance_vnd': reservedBalanceVnd,
      if (allowNegativeException != null)
        'allow_negative_exception': allowNegativeException,
      if (targetAmountVnd != null) 'target_amount_vnd': targetAmountVnd,
      if (targetDateMs != null) 'target_date_ms': targetDateMs,
      if (periodLimitVnd != null) 'period_limit_vnd': periodLimitVnd,
      if (rolloverEnabled != null) 'rollover_enabled': rolloverEnabled,
      if (priority != null) 'priority': priority,
      if (isArchived != null) 'is_archived': isArchived,
    });
  }

  EnvelopesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? policy,
      Value<int>? reservedBalanceVnd,
      Value<bool>? allowNegativeException,
      Value<int?>? targetAmountVnd,
      Value<int?>? targetDateMs,
      Value<int?>? periodLimitVnd,
      Value<bool>? rolloverEnabled,
      Value<int>? priority,
      Value<bool>? isArchived}) {
    return EnvelopesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      policy: policy ?? this.policy,
      reservedBalanceVnd: reservedBalanceVnd ?? this.reservedBalanceVnd,
      allowNegativeException:
          allowNegativeException ?? this.allowNegativeException,
      targetAmountVnd: targetAmountVnd ?? this.targetAmountVnd,
      targetDateMs: targetDateMs ?? this.targetDateMs,
      periodLimitVnd: periodLimitVnd ?? this.periodLimitVnd,
      rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
      priority: priority ?? this.priority,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (policy.present) {
      map['policy'] = Variable<String>(policy.value);
    }
    if (reservedBalanceVnd.present) {
      map['reserved_balance_vnd'] = Variable<int>(reservedBalanceVnd.value);
    }
    if (allowNegativeException.present) {
      map['allow_negative_exception'] =
          Variable<bool>(allowNegativeException.value);
    }
    if (targetAmountVnd.present) {
      map['target_amount_vnd'] = Variable<int>(targetAmountVnd.value);
    }
    if (targetDateMs.present) {
      map['target_date_ms'] = Variable<int>(targetDateMs.value);
    }
    if (periodLimitVnd.present) {
      map['period_limit_vnd'] = Variable<int>(periodLimitVnd.value);
    }
    if (rolloverEnabled.present) {
      map['rollover_enabled'] = Variable<bool>(rolloverEnabled.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvelopesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('policy: $policy, ')
          ..write('reservedBalanceVnd: $reservedBalanceVnd, ')
          ..write('allowNegativeException: $allowNegativeException, ')
          ..write('targetAmountVnd: $targetAmountVnd, ')
          ..write('targetDateMs: $targetDateMs, ')
          ..write('periodLimitVnd: $periodLimitVnd, ')
          ..write('rolloverEnabled: $rolloverEnabled, ')
          ..write('priority: $priority, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }
}

class $JournalPostingsTable extends JournalPostings
    with TableInfo<$JournalPostingsTable, JournalPosting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalPostingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
      'transaction_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES journal_transactions (id) ON DELETE CASCADE'));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES ledger_accounts (id) ON DELETE RESTRICT'));
  static const VerificationMeta _debitVndMeta =
      const VerificationMeta('debitVnd');
  @override
  late final GeneratedColumn<int> debitVnd = GeneratedColumn<int>(
      'debit_vnd', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _creditVndMeta =
      const VerificationMeta('creditVnd');
  @override
  late final GeneratedColumn<int> creditVnd = GeneratedColumn<int>(
      'credit_vnd', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _envelopeIdMeta =
      const VerificationMeta('envelopeId');
  @override
  late final GeneratedColumn<int> envelopeId = GeneratedColumn<int>(
      'envelope_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES envelopes (id) ON DELETE SET NULL'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        transactionId,
        accountId,
        debitVnd,
        creditVnd,
        categoryId,
        envelopeId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_postings';
  @override
  VerificationContext validateIntegrity(Insertable<JournalPosting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('debit_vnd')) {
      context.handle(_debitVndMeta,
          debitVnd.isAcceptableOrUnknown(data['debit_vnd']!, _debitVndMeta));
    }
    if (data.containsKey('credit_vnd')) {
      context.handle(_creditVndMeta,
          creditVnd.isAcceptableOrUnknown(data['credit_vnd']!, _creditVndMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('envelope_id')) {
      context.handle(
          _envelopeIdMeta,
          envelopeId.isAcceptableOrUnknown(
              data['envelope_id']!, _envelopeIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalPosting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalPosting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}transaction_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      debitVnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}debit_vnd'])!,
      creditVnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}credit_vnd'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      envelopeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}envelope_id']),
    );
  }

  @override
  $JournalPostingsTable createAlias(String alias) {
    return $JournalPostingsTable(attachedDatabase, alias);
  }
}

class JournalPosting extends DataClass implements Insertable<JournalPosting> {
  final int id;
  final int transactionId;
  final int accountId;
  final int debitVnd;
  final int creditVnd;
  final int? categoryId;
  final int? envelopeId;
  const JournalPosting(
      {required this.id,
      required this.transactionId,
      required this.accountId,
      required this.debitVnd,
      required this.creditVnd,
      this.categoryId,
      this.envelopeId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_id'] = Variable<int>(transactionId);
    map['account_id'] = Variable<int>(accountId);
    map['debit_vnd'] = Variable<int>(debitVnd);
    map['credit_vnd'] = Variable<int>(creditVnd);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || envelopeId != null) {
      map['envelope_id'] = Variable<int>(envelopeId);
    }
    return map;
  }

  JournalPostingsCompanion toCompanion(bool nullToAbsent) {
    return JournalPostingsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      accountId: Value(accountId),
      debitVnd: Value(debitVnd),
      creditVnd: Value(creditVnd),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      envelopeId: envelopeId == null && nullToAbsent
          ? const Value.absent()
          : Value(envelopeId),
    );
  }

  factory JournalPosting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalPosting(
      id: serializer.fromJson<int>(json['id']),
      transactionId: serializer.fromJson<int>(json['transactionId']),
      accountId: serializer.fromJson<int>(json['accountId']),
      debitVnd: serializer.fromJson<int>(json['debitVnd']),
      creditVnd: serializer.fromJson<int>(json['creditVnd']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      envelopeId: serializer.fromJson<int?>(json['envelopeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionId': serializer.toJson<int>(transactionId),
      'accountId': serializer.toJson<int>(accountId),
      'debitVnd': serializer.toJson<int>(debitVnd),
      'creditVnd': serializer.toJson<int>(creditVnd),
      'categoryId': serializer.toJson<int?>(categoryId),
      'envelopeId': serializer.toJson<int?>(envelopeId),
    };
  }

  JournalPosting copyWith(
          {int? id,
          int? transactionId,
          int? accountId,
          int? debitVnd,
          int? creditVnd,
          Value<int?> categoryId = const Value.absent(),
          Value<int?> envelopeId = const Value.absent()}) =>
      JournalPosting(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        accountId: accountId ?? this.accountId,
        debitVnd: debitVnd ?? this.debitVnd,
        creditVnd: creditVnd ?? this.creditVnd,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        envelopeId: envelopeId.present ? envelopeId.value : this.envelopeId,
      );
  JournalPosting copyWithCompanion(JournalPostingsCompanion data) {
    return JournalPosting(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      debitVnd: data.debitVnd.present ? data.debitVnd.value : this.debitVnd,
      creditVnd: data.creditVnd.present ? data.creditVnd.value : this.creditVnd,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      envelopeId:
          data.envelopeId.present ? data.envelopeId.value : this.envelopeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalPosting(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('debitVnd: $debitVnd, ')
          ..write('creditVnd: $creditVnd, ')
          ..write('categoryId: $categoryId, ')
          ..write('envelopeId: $envelopeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionId, accountId, debitVnd,
      creditVnd, categoryId, envelopeId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalPosting &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.accountId == this.accountId &&
          other.debitVnd == this.debitVnd &&
          other.creditVnd == this.creditVnd &&
          other.categoryId == this.categoryId &&
          other.envelopeId == this.envelopeId);
}

class JournalPostingsCompanion extends UpdateCompanion<JournalPosting> {
  final Value<int> id;
  final Value<int> transactionId;
  final Value<int> accountId;
  final Value<int> debitVnd;
  final Value<int> creditVnd;
  final Value<int?> categoryId;
  final Value<int?> envelopeId;
  const JournalPostingsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.debitVnd = const Value.absent(),
    this.creditVnd = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.envelopeId = const Value.absent(),
  });
  JournalPostingsCompanion.insert({
    this.id = const Value.absent(),
    required int transactionId,
    required int accountId,
    this.debitVnd = const Value.absent(),
    this.creditVnd = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.envelopeId = const Value.absent(),
  })  : transactionId = Value(transactionId),
        accountId = Value(accountId);
  static Insertable<JournalPosting> custom({
    Expression<int>? id,
    Expression<int>? transactionId,
    Expression<int>? accountId,
    Expression<int>? debitVnd,
    Expression<int>? creditVnd,
    Expression<int>? categoryId,
    Expression<int>? envelopeId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (accountId != null) 'account_id': accountId,
      if (debitVnd != null) 'debit_vnd': debitVnd,
      if (creditVnd != null) 'credit_vnd': creditVnd,
      if (categoryId != null) 'category_id': categoryId,
      if (envelopeId != null) 'envelope_id': envelopeId,
    });
  }

  JournalPostingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? transactionId,
      Value<int>? accountId,
      Value<int>? debitVnd,
      Value<int>? creditVnd,
      Value<int?>? categoryId,
      Value<int?>? envelopeId}) {
    return JournalPostingsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      accountId: accountId ?? this.accountId,
      debitVnd: debitVnd ?? this.debitVnd,
      creditVnd: creditVnd ?? this.creditVnd,
      categoryId: categoryId ?? this.categoryId,
      envelopeId: envelopeId ?? this.envelopeId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (debitVnd.present) {
      map['debit_vnd'] = Variable<int>(debitVnd.value);
    }
    if (creditVnd.present) {
      map['credit_vnd'] = Variable<int>(creditVnd.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (envelopeId.present) {
      map['envelope_id'] = Variable<int>(envelopeId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalPostingsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('debitVnd: $debitVnd, ')
          ..write('creditVnd: $creditVnd, ')
          ..write('categoryId: $categoryId, ')
          ..write('envelopeId: $envelopeId')
          ..write(')'))
        .toString();
  }
}

class $ScheduledItemsTable extends ScheduledItems
    with TableInfo<$ScheduledItemsTable, ScheduledItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduledItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountVndMeta =
      const VerificationMeta('amountVnd');
  @override
  late final GeneratedColumn<int> amountVnd = GeneratedColumn<int>(
      'amount_vnd', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMsMeta =
      const VerificationMeta('dueDateMs');
  @override
  late final GeneratedColumn<int> dueDateMs = GeneratedColumn<int>(
      'due_date_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _recurrenceMeta =
      const VerificationMeta('recurrence');
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
      'recurrence', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('NONE'));
  static const VerificationMeta _anchorDayOfMonthMeta =
      const VerificationMeta('anchorDayOfMonth');
  @override
  late final GeneratedColumn<int> anchorDayOfMonth = GeneratedColumn<int>(
      'anchor_day_of_month', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _linkedEnvelopeIdMeta =
      const VerificationMeta('linkedEnvelopeId');
  @override
  late final GeneratedColumn<int> linkedEnvelopeId = GeneratedColumn<int>(
      'linked_envelope_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES envelopes (id) ON DELETE SET NULL'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PENDING'));
  static const VerificationMeta _paidTransactionIdMeta =
      const VerificationMeta('paidTransactionId');
  @override
  late final GeneratedColumn<int> paidTransactionId = GeneratedColumn<int>(
      'paid_transaction_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES journal_transactions (id) ON DELETE SET NULL'));
  static const VerificationMeta _reminderDaysBeforeMeta =
      const VerificationMeta('reminderDaysBefore');
  @override
  late final GeneratedColumn<int> reminderDaysBefore = GeneratedColumn<int>(
      'reminder_days_before', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        title,
        amountVnd,
        dueDateMs,
        recurrence,
        anchorDayOfMonth,
        categoryId,
        linkedEnvelopeId,
        status,
        paidTransactionId,
        reminderDaysBefore
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheduled_items';
  @override
  VerificationContext validateIntegrity(Insertable<ScheduledItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount_vnd')) {
      context.handle(_amountVndMeta,
          amountVnd.isAcceptableOrUnknown(data['amount_vnd']!, _amountVndMeta));
    } else if (isInserting) {
      context.missing(_amountVndMeta);
    }
    if (data.containsKey('due_date_ms')) {
      context.handle(
          _dueDateMsMeta,
          dueDateMs.isAcceptableOrUnknown(
              data['due_date_ms']!, _dueDateMsMeta));
    } else if (isInserting) {
      context.missing(_dueDateMsMeta);
    }
    if (data.containsKey('recurrence')) {
      context.handle(
          _recurrenceMeta,
          recurrence.isAcceptableOrUnknown(
              data['recurrence']!, _recurrenceMeta));
    }
    if (data.containsKey('anchor_day_of_month')) {
      context.handle(
          _anchorDayOfMonthMeta,
          anchorDayOfMonth.isAcceptableOrUnknown(
              data['anchor_day_of_month']!, _anchorDayOfMonthMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('linked_envelope_id')) {
      context.handle(
          _linkedEnvelopeIdMeta,
          linkedEnvelopeId.isAcceptableOrUnknown(
              data['linked_envelope_id']!, _linkedEnvelopeIdMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('paid_transaction_id')) {
      context.handle(
          _paidTransactionIdMeta,
          paidTransactionId.isAcceptableOrUnknown(
              data['paid_transaction_id']!, _paidTransactionIdMeta));
    }
    if (data.containsKey('reminder_days_before')) {
      context.handle(
          _reminderDaysBeforeMeta,
          reminderDaysBefore.isAcceptableOrUnknown(
              data['reminder_days_before']!, _reminderDaysBeforeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduledItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduledItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      amountVnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_vnd'])!,
      dueDateMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}due_date_ms'])!,
      recurrence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurrence'])!,
      anchorDayOfMonth: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}anchor_day_of_month']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      linkedEnvelopeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}linked_envelope_id']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      paidTransactionId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}paid_transaction_id']),
      reminderDaysBefore: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}reminder_days_before'])!,
    );
  }

  @override
  $ScheduledItemsTable createAlias(String alias) {
    return $ScheduledItemsTable(attachedDatabase, alias);
  }
}

class ScheduledItem extends DataClass implements Insertable<ScheduledItem> {
  final int id;
  final String kind;
  final String title;
  final int amountVnd;
  final int dueDateMs;
  final String recurrence;
  final int? anchorDayOfMonth;
  final int? categoryId;
  final int? linkedEnvelopeId;
  final String status;
  final int? paidTransactionId;
  final int reminderDaysBefore;
  const ScheduledItem(
      {required this.id,
      required this.kind,
      required this.title,
      required this.amountVnd,
      required this.dueDateMs,
      required this.recurrence,
      this.anchorDayOfMonth,
      this.categoryId,
      this.linkedEnvelopeId,
      required this.status,
      this.paidTransactionId,
      required this.reminderDaysBefore});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    map['amount_vnd'] = Variable<int>(amountVnd);
    map['due_date_ms'] = Variable<int>(dueDateMs);
    map['recurrence'] = Variable<String>(recurrence);
    if (!nullToAbsent || anchorDayOfMonth != null) {
      map['anchor_day_of_month'] = Variable<int>(anchorDayOfMonth);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || linkedEnvelopeId != null) {
      map['linked_envelope_id'] = Variable<int>(linkedEnvelopeId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || paidTransactionId != null) {
      map['paid_transaction_id'] = Variable<int>(paidTransactionId);
    }
    map['reminder_days_before'] = Variable<int>(reminderDaysBefore);
    return map;
  }

  ScheduledItemsCompanion toCompanion(bool nullToAbsent) {
    return ScheduledItemsCompanion(
      id: Value(id),
      kind: Value(kind),
      title: Value(title),
      amountVnd: Value(amountVnd),
      dueDateMs: Value(dueDateMs),
      recurrence: Value(recurrence),
      anchorDayOfMonth: anchorDayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorDayOfMonth),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      linkedEnvelopeId: linkedEnvelopeId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedEnvelopeId),
      status: Value(status),
      paidTransactionId: paidTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(paidTransactionId),
      reminderDaysBefore: Value(reminderDaysBefore),
    );
  }

  factory ScheduledItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduledItem(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      amountVnd: serializer.fromJson<int>(json['amountVnd']),
      dueDateMs: serializer.fromJson<int>(json['dueDateMs']),
      recurrence: serializer.fromJson<String>(json['recurrence']),
      anchorDayOfMonth: serializer.fromJson<int?>(json['anchorDayOfMonth']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      linkedEnvelopeId: serializer.fromJson<int?>(json['linkedEnvelopeId']),
      status: serializer.fromJson<String>(json['status']),
      paidTransactionId: serializer.fromJson<int?>(json['paidTransactionId']),
      reminderDaysBefore: serializer.fromJson<int>(json['reminderDaysBefore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'amountVnd': serializer.toJson<int>(amountVnd),
      'dueDateMs': serializer.toJson<int>(dueDateMs),
      'recurrence': serializer.toJson<String>(recurrence),
      'anchorDayOfMonth': serializer.toJson<int?>(anchorDayOfMonth),
      'categoryId': serializer.toJson<int?>(categoryId),
      'linkedEnvelopeId': serializer.toJson<int?>(linkedEnvelopeId),
      'status': serializer.toJson<String>(status),
      'paidTransactionId': serializer.toJson<int?>(paidTransactionId),
      'reminderDaysBefore': serializer.toJson<int>(reminderDaysBefore),
    };
  }

  ScheduledItem copyWith(
          {int? id,
          String? kind,
          String? title,
          int? amountVnd,
          int? dueDateMs,
          String? recurrence,
          Value<int?> anchorDayOfMonth = const Value.absent(),
          Value<int?> categoryId = const Value.absent(),
          Value<int?> linkedEnvelopeId = const Value.absent(),
          String? status,
          Value<int?> paidTransactionId = const Value.absent(),
          int? reminderDaysBefore}) =>
      ScheduledItem(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        title: title ?? this.title,
        amountVnd: amountVnd ?? this.amountVnd,
        dueDateMs: dueDateMs ?? this.dueDateMs,
        recurrence: recurrence ?? this.recurrence,
        anchorDayOfMonth: anchorDayOfMonth.present
            ? anchorDayOfMonth.value
            : this.anchorDayOfMonth,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        linkedEnvelopeId: linkedEnvelopeId.present
            ? linkedEnvelopeId.value
            : this.linkedEnvelopeId,
        status: status ?? this.status,
        paidTransactionId: paidTransactionId.present
            ? paidTransactionId.value
            : this.paidTransactionId,
        reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      );
  ScheduledItem copyWithCompanion(ScheduledItemsCompanion data) {
    return ScheduledItem(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      amountVnd: data.amountVnd.present ? data.amountVnd.value : this.amountVnd,
      dueDateMs: data.dueDateMs.present ? data.dueDateMs.value : this.dueDateMs,
      recurrence:
          data.recurrence.present ? data.recurrence.value : this.recurrence,
      anchorDayOfMonth: data.anchorDayOfMonth.present
          ? data.anchorDayOfMonth.value
          : this.anchorDayOfMonth,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      linkedEnvelopeId: data.linkedEnvelopeId.present
          ? data.linkedEnvelopeId.value
          : this.linkedEnvelopeId,
      status: data.status.present ? data.status.value : this.status,
      paidTransactionId: data.paidTransactionId.present
          ? data.paidTransactionId.value
          : this.paidTransactionId,
      reminderDaysBefore: data.reminderDaysBefore.present
          ? data.reminderDaysBefore.value
          : this.reminderDaysBefore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledItem(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('dueDateMs: $dueDateMs, ')
          ..write('recurrence: $recurrence, ')
          ..write('anchorDayOfMonth: $anchorDayOfMonth, ')
          ..write('categoryId: $categoryId, ')
          ..write('linkedEnvelopeId: $linkedEnvelopeId, ')
          ..write('status: $status, ')
          ..write('paidTransactionId: $paidTransactionId, ')
          ..write('reminderDaysBefore: $reminderDaysBefore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      kind,
      title,
      amountVnd,
      dueDateMs,
      recurrence,
      anchorDayOfMonth,
      categoryId,
      linkedEnvelopeId,
      status,
      paidTransactionId,
      reminderDaysBefore);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduledItem &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.amountVnd == this.amountVnd &&
          other.dueDateMs == this.dueDateMs &&
          other.recurrence == this.recurrence &&
          other.anchorDayOfMonth == this.anchorDayOfMonth &&
          other.categoryId == this.categoryId &&
          other.linkedEnvelopeId == this.linkedEnvelopeId &&
          other.status == this.status &&
          other.paidTransactionId == this.paidTransactionId &&
          other.reminderDaysBefore == this.reminderDaysBefore);
}

class ScheduledItemsCompanion extends UpdateCompanion<ScheduledItem> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> title;
  final Value<int> amountVnd;
  final Value<int> dueDateMs;
  final Value<String> recurrence;
  final Value<int?> anchorDayOfMonth;
  final Value<int?> categoryId;
  final Value<int?> linkedEnvelopeId;
  final Value<String> status;
  final Value<int?> paidTransactionId;
  final Value<int> reminderDaysBefore;
  const ScheduledItemsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.amountVnd = const Value.absent(),
    this.dueDateMs = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.anchorDayOfMonth = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.linkedEnvelopeId = const Value.absent(),
    this.status = const Value.absent(),
    this.paidTransactionId = const Value.absent(),
    this.reminderDaysBefore = const Value.absent(),
  });
  ScheduledItemsCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String title,
    required int amountVnd,
    required int dueDateMs,
    this.recurrence = const Value.absent(),
    this.anchorDayOfMonth = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.linkedEnvelopeId = const Value.absent(),
    this.status = const Value.absent(),
    this.paidTransactionId = const Value.absent(),
    this.reminderDaysBefore = const Value.absent(),
  })  : kind = Value(kind),
        title = Value(title),
        amountVnd = Value(amountVnd),
        dueDateMs = Value(dueDateMs);
  static Insertable<ScheduledItem> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<int>? amountVnd,
    Expression<int>? dueDateMs,
    Expression<String>? recurrence,
    Expression<int>? anchorDayOfMonth,
    Expression<int>? categoryId,
    Expression<int>? linkedEnvelopeId,
    Expression<String>? status,
    Expression<int>? paidTransactionId,
    Expression<int>? reminderDaysBefore,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (amountVnd != null) 'amount_vnd': amountVnd,
      if (dueDateMs != null) 'due_date_ms': dueDateMs,
      if (recurrence != null) 'recurrence': recurrence,
      if (anchorDayOfMonth != null) 'anchor_day_of_month': anchorDayOfMonth,
      if (categoryId != null) 'category_id': categoryId,
      if (linkedEnvelopeId != null) 'linked_envelope_id': linkedEnvelopeId,
      if (status != null) 'status': status,
      if (paidTransactionId != null) 'paid_transaction_id': paidTransactionId,
      if (reminderDaysBefore != null)
        'reminder_days_before': reminderDaysBefore,
    });
  }

  ScheduledItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? kind,
      Value<String>? title,
      Value<int>? amountVnd,
      Value<int>? dueDateMs,
      Value<String>? recurrence,
      Value<int?>? anchorDayOfMonth,
      Value<int?>? categoryId,
      Value<int?>? linkedEnvelopeId,
      Value<String>? status,
      Value<int?>? paidTransactionId,
      Value<int>? reminderDaysBefore}) {
    return ScheduledItemsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      amountVnd: amountVnd ?? this.amountVnd,
      dueDateMs: dueDateMs ?? this.dueDateMs,
      recurrence: recurrence ?? this.recurrence,
      anchorDayOfMonth: anchorDayOfMonth ?? this.anchorDayOfMonth,
      categoryId: categoryId ?? this.categoryId,
      linkedEnvelopeId: linkedEnvelopeId ?? this.linkedEnvelopeId,
      status: status ?? this.status,
      paidTransactionId: paidTransactionId ?? this.paidTransactionId,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amountVnd.present) {
      map['amount_vnd'] = Variable<int>(amountVnd.value);
    }
    if (dueDateMs.present) {
      map['due_date_ms'] = Variable<int>(dueDateMs.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (anchorDayOfMonth.present) {
      map['anchor_day_of_month'] = Variable<int>(anchorDayOfMonth.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (linkedEnvelopeId.present) {
      map['linked_envelope_id'] = Variable<int>(linkedEnvelopeId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (paidTransactionId.present) {
      map['paid_transaction_id'] = Variable<int>(paidTransactionId.value);
    }
    if (reminderDaysBefore.present) {
      map['reminder_days_before'] = Variable<int>(reminderDaysBefore.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledItemsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('dueDateMs: $dueDateMs, ')
          ..write('recurrence: $recurrence, ')
          ..write('anchorDayOfMonth: $anchorDayOfMonth, ')
          ..write('categoryId: $categoryId, ')
          ..write('linkedEnvelopeId: $linkedEnvelopeId, ')
          ..write('status: $status, ')
          ..write('paidTransactionId: $paidTransactionId, ')
          ..write('reminderDaysBefore: $reminderDaysBefore')
          ..write(')'))
        .toString();
  }
}

class $EnvelopeMovementsTable extends EnvelopeMovements
    with TableInfo<$EnvelopeMovementsTable, EnvelopeMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvelopeMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _movementTypeMeta =
      const VerificationMeta('movementType');
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
      'movement_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountVndMeta =
      const VerificationMeta('amountVnd');
  @override
  late final GeneratedColumn<int> amountVnd = GeneratedColumn<int>(
      'amount_vnd', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sourceEnvelopeIdMeta =
      const VerificationMeta('sourceEnvelopeId');
  @override
  late final GeneratedColumn<int> sourceEnvelopeId = GeneratedColumn<int>(
      'source_envelope_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES envelopes (id) ON DELETE RESTRICT'));
  static const VerificationMeta _destEnvelopeIdMeta =
      const VerificationMeta('destEnvelopeId');
  @override
  late final GeneratedColumn<int> destEnvelopeId = GeneratedColumn<int>(
      'dest_envelope_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES envelopes (id) ON DELETE RESTRICT'));
  static const VerificationMeta _linkedTransactionIdMeta =
      const VerificationMeta('linkedTransactionId');
  @override
  late final GeneratedColumn<int> linkedTransactionId = GeneratedColumn<int>(
      'linked_transaction_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES journal_transactions (id) ON DELETE SET NULL'));
  static const VerificationMeta _linkedObligationIdMeta =
      const VerificationMeta('linkedObligationId');
  @override
  late final GeneratedColumn<int> linkedObligationId = GeneratedColumn<int>(
      'linked_obligation_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES scheduled_items (id) ON DELETE SET NULL'));
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        movementType,
        amountVnd,
        sourceEnvelopeId,
        destEnvelopeId,
        linkedTransactionId,
        linkedObligationId,
        occurredAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'envelope_movements';
  @override
  VerificationContext validateIntegrity(Insertable<EnvelopeMovement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('movement_type')) {
      context.handle(
          _movementTypeMeta,
          movementType.isAcceptableOrUnknown(
              data['movement_type']!, _movementTypeMeta));
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('amount_vnd')) {
      context.handle(_amountVndMeta,
          amountVnd.isAcceptableOrUnknown(data['amount_vnd']!, _amountVndMeta));
    } else if (isInserting) {
      context.missing(_amountVndMeta);
    }
    if (data.containsKey('source_envelope_id')) {
      context.handle(
          _sourceEnvelopeIdMeta,
          sourceEnvelopeId.isAcceptableOrUnknown(
              data['source_envelope_id']!, _sourceEnvelopeIdMeta));
    }
    if (data.containsKey('dest_envelope_id')) {
      context.handle(
          _destEnvelopeIdMeta,
          destEnvelopeId.isAcceptableOrUnknown(
              data['dest_envelope_id']!, _destEnvelopeIdMeta));
    }
    if (data.containsKey('linked_transaction_id')) {
      context.handle(
          _linkedTransactionIdMeta,
          linkedTransactionId.isAcceptableOrUnknown(
              data['linked_transaction_id']!, _linkedTransactionIdMeta));
    }
    if (data.containsKey('linked_obligation_id')) {
      context.handle(
          _linkedObligationIdMeta,
          linkedObligationId.isAcceptableOrUnknown(
              data['linked_obligation_id']!, _linkedObligationIdMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnvelopeMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvelopeMovement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      movementType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}movement_type'])!,
      amountVnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_vnd'])!,
      sourceEnvelopeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source_envelope_id']),
      destEnvelopeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dest_envelope_id']),
      linkedTransactionId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}linked_transaction_id']),
      linkedObligationId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}linked_obligation_id']),
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}occurred_at'])!,
    );
  }

  @override
  $EnvelopeMovementsTable createAlias(String alias) {
    return $EnvelopeMovementsTable(attachedDatabase, alias);
  }
}

class EnvelopeMovement extends DataClass
    implements Insertable<EnvelopeMovement> {
  final int id;
  final String movementType;
  final int amountVnd;
  final int? sourceEnvelopeId;
  final int? destEnvelopeId;
  final int? linkedTransactionId;
  final int? linkedObligationId;
  final int occurredAt;
  const EnvelopeMovement(
      {required this.id,
      required this.movementType,
      required this.amountVnd,
      this.sourceEnvelopeId,
      this.destEnvelopeId,
      this.linkedTransactionId,
      this.linkedObligationId,
      required this.occurredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['movement_type'] = Variable<String>(movementType);
    map['amount_vnd'] = Variable<int>(amountVnd);
    if (!nullToAbsent || sourceEnvelopeId != null) {
      map['source_envelope_id'] = Variable<int>(sourceEnvelopeId);
    }
    if (!nullToAbsent || destEnvelopeId != null) {
      map['dest_envelope_id'] = Variable<int>(destEnvelopeId);
    }
    if (!nullToAbsent || linkedTransactionId != null) {
      map['linked_transaction_id'] = Variable<int>(linkedTransactionId);
    }
    if (!nullToAbsent || linkedObligationId != null) {
      map['linked_obligation_id'] = Variable<int>(linkedObligationId);
    }
    map['occurred_at'] = Variable<int>(occurredAt);
    return map;
  }

  EnvelopeMovementsCompanion toCompanion(bool nullToAbsent) {
    return EnvelopeMovementsCompanion(
      id: Value(id),
      movementType: Value(movementType),
      amountVnd: Value(amountVnd),
      sourceEnvelopeId: sourceEnvelopeId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceEnvelopeId),
      destEnvelopeId: destEnvelopeId == null && nullToAbsent
          ? const Value.absent()
          : Value(destEnvelopeId),
      linkedTransactionId: linkedTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTransactionId),
      linkedObligationId: linkedObligationId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedObligationId),
      occurredAt: Value(occurredAt),
    );
  }

  factory EnvelopeMovement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvelopeMovement(
      id: serializer.fromJson<int>(json['id']),
      movementType: serializer.fromJson<String>(json['movementType']),
      amountVnd: serializer.fromJson<int>(json['amountVnd']),
      sourceEnvelopeId: serializer.fromJson<int?>(json['sourceEnvelopeId']),
      destEnvelopeId: serializer.fromJson<int?>(json['destEnvelopeId']),
      linkedTransactionId:
          serializer.fromJson<int?>(json['linkedTransactionId']),
      linkedObligationId: serializer.fromJson<int?>(json['linkedObligationId']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'movementType': serializer.toJson<String>(movementType),
      'amountVnd': serializer.toJson<int>(amountVnd),
      'sourceEnvelopeId': serializer.toJson<int?>(sourceEnvelopeId),
      'destEnvelopeId': serializer.toJson<int?>(destEnvelopeId),
      'linkedTransactionId': serializer.toJson<int?>(linkedTransactionId),
      'linkedObligationId': serializer.toJson<int?>(linkedObligationId),
      'occurredAt': serializer.toJson<int>(occurredAt),
    };
  }

  EnvelopeMovement copyWith(
          {int? id,
          String? movementType,
          int? amountVnd,
          Value<int?> sourceEnvelopeId = const Value.absent(),
          Value<int?> destEnvelopeId = const Value.absent(),
          Value<int?> linkedTransactionId = const Value.absent(),
          Value<int?> linkedObligationId = const Value.absent(),
          int? occurredAt}) =>
      EnvelopeMovement(
        id: id ?? this.id,
        movementType: movementType ?? this.movementType,
        amountVnd: amountVnd ?? this.amountVnd,
        sourceEnvelopeId: sourceEnvelopeId.present
            ? sourceEnvelopeId.value
            : this.sourceEnvelopeId,
        destEnvelopeId:
            destEnvelopeId.present ? destEnvelopeId.value : this.destEnvelopeId,
        linkedTransactionId: linkedTransactionId.present
            ? linkedTransactionId.value
            : this.linkedTransactionId,
        linkedObligationId: linkedObligationId.present
            ? linkedObligationId.value
            : this.linkedObligationId,
        occurredAt: occurredAt ?? this.occurredAt,
      );
  EnvelopeMovement copyWithCompanion(EnvelopeMovementsCompanion data) {
    return EnvelopeMovement(
      id: data.id.present ? data.id.value : this.id,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      amountVnd: data.amountVnd.present ? data.amountVnd.value : this.amountVnd,
      sourceEnvelopeId: data.sourceEnvelopeId.present
          ? data.sourceEnvelopeId.value
          : this.sourceEnvelopeId,
      destEnvelopeId: data.destEnvelopeId.present
          ? data.destEnvelopeId.value
          : this.destEnvelopeId,
      linkedTransactionId: data.linkedTransactionId.present
          ? data.linkedTransactionId.value
          : this.linkedTransactionId,
      linkedObligationId: data.linkedObligationId.present
          ? data.linkedObligationId.value
          : this.linkedObligationId,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvelopeMovement(')
          ..write('id: $id, ')
          ..write('movementType: $movementType, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('sourceEnvelopeId: $sourceEnvelopeId, ')
          ..write('destEnvelopeId: $destEnvelopeId, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('linkedObligationId: $linkedObligationId, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, movementType, amountVnd, sourceEnvelopeId,
      destEnvelopeId, linkedTransactionId, linkedObligationId, occurredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvelopeMovement &&
          other.id == this.id &&
          other.movementType == this.movementType &&
          other.amountVnd == this.amountVnd &&
          other.sourceEnvelopeId == this.sourceEnvelopeId &&
          other.destEnvelopeId == this.destEnvelopeId &&
          other.linkedTransactionId == this.linkedTransactionId &&
          other.linkedObligationId == this.linkedObligationId &&
          other.occurredAt == this.occurredAt);
}

class EnvelopeMovementsCompanion extends UpdateCompanion<EnvelopeMovement> {
  final Value<int> id;
  final Value<String> movementType;
  final Value<int> amountVnd;
  final Value<int?> sourceEnvelopeId;
  final Value<int?> destEnvelopeId;
  final Value<int?> linkedTransactionId;
  final Value<int?> linkedObligationId;
  final Value<int> occurredAt;
  const EnvelopeMovementsCompanion({
    this.id = const Value.absent(),
    this.movementType = const Value.absent(),
    this.amountVnd = const Value.absent(),
    this.sourceEnvelopeId = const Value.absent(),
    this.destEnvelopeId = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.linkedObligationId = const Value.absent(),
    this.occurredAt = const Value.absent(),
  });
  EnvelopeMovementsCompanion.insert({
    this.id = const Value.absent(),
    required String movementType,
    required int amountVnd,
    this.sourceEnvelopeId = const Value.absent(),
    this.destEnvelopeId = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.linkedObligationId = const Value.absent(),
    required int occurredAt,
  })  : movementType = Value(movementType),
        amountVnd = Value(amountVnd),
        occurredAt = Value(occurredAt);
  static Insertable<EnvelopeMovement> custom({
    Expression<int>? id,
    Expression<String>? movementType,
    Expression<int>? amountVnd,
    Expression<int>? sourceEnvelopeId,
    Expression<int>? destEnvelopeId,
    Expression<int>? linkedTransactionId,
    Expression<int>? linkedObligationId,
    Expression<int>? occurredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (movementType != null) 'movement_type': movementType,
      if (amountVnd != null) 'amount_vnd': amountVnd,
      if (sourceEnvelopeId != null) 'source_envelope_id': sourceEnvelopeId,
      if (destEnvelopeId != null) 'dest_envelope_id': destEnvelopeId,
      if (linkedTransactionId != null)
        'linked_transaction_id': linkedTransactionId,
      if (linkedObligationId != null)
        'linked_obligation_id': linkedObligationId,
      if (occurredAt != null) 'occurred_at': occurredAt,
    });
  }

  EnvelopeMovementsCompanion copyWith(
      {Value<int>? id,
      Value<String>? movementType,
      Value<int>? amountVnd,
      Value<int?>? sourceEnvelopeId,
      Value<int?>? destEnvelopeId,
      Value<int?>? linkedTransactionId,
      Value<int?>? linkedObligationId,
      Value<int>? occurredAt}) {
    return EnvelopeMovementsCompanion(
      id: id ?? this.id,
      movementType: movementType ?? this.movementType,
      amountVnd: amountVnd ?? this.amountVnd,
      sourceEnvelopeId: sourceEnvelopeId ?? this.sourceEnvelopeId,
      destEnvelopeId: destEnvelopeId ?? this.destEnvelopeId,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      linkedObligationId: linkedObligationId ?? this.linkedObligationId,
      occurredAt: occurredAt ?? this.occurredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (amountVnd.present) {
      map['amount_vnd'] = Variable<int>(amountVnd.value);
    }
    if (sourceEnvelopeId.present) {
      map['source_envelope_id'] = Variable<int>(sourceEnvelopeId.value);
    }
    if (destEnvelopeId.present) {
      map['dest_envelope_id'] = Variable<int>(destEnvelopeId.value);
    }
    if (linkedTransactionId.present) {
      map['linked_transaction_id'] = Variable<int>(linkedTransactionId.value);
    }
    if (linkedObligationId.present) {
      map['linked_obligation_id'] = Variable<int>(linkedObligationId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvelopeMovementsCompanion(')
          ..write('id: $id, ')
          ..write('movementType: $movementType, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('sourceEnvelopeId: $sourceEnvelopeId, ')
          ..write('destEnvelopeId: $destEnvelopeId, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('linkedObligationId: $linkedObligationId, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }
}

class $CategoryBudgetsTable extends CategoryBudgets
    with TableInfo<$CategoryBudgetsTable, CategoryBudget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE CASCADE'));
  static const VerificationMeta _yearMonthMeta =
      const VerificationMeta('yearMonth');
  @override
  late final GeneratedColumn<int> yearMonth = GeneratedColumn<int>(
      'year_month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _limitVndMeta =
      const VerificationMeta('limitVnd');
  @override
  late final GeneratedColumn<int> limitVnd = GeneratedColumn<int>(
      'limit_vnd', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _alertThresholdPctMeta =
      const VerificationMeta('alertThresholdPct');
  @override
  late final GeneratedColumn<int> alertThresholdPct = GeneratedColumn<int>(
      'alert_threshold_pct', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(80));
  @override
  List<GeneratedColumn> get $columns =>
      [id, categoryId, yearMonth, limitVnd, alertThresholdPct];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_budgets';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryBudget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('year_month')) {
      context.handle(_yearMonthMeta,
          yearMonth.isAcceptableOrUnknown(data['year_month']!, _yearMonthMeta));
    } else if (isInserting) {
      context.missing(_yearMonthMeta);
    }
    if (data.containsKey('limit_vnd')) {
      context.handle(_limitVndMeta,
          limitVnd.isAcceptableOrUnknown(data['limit_vnd']!, _limitVndMeta));
    } else if (isInserting) {
      context.missing(_limitVndMeta);
    }
    if (data.containsKey('alert_threshold_pct')) {
      context.handle(
          _alertThresholdPctMeta,
          alertThresholdPct.isAcceptableOrUnknown(
              data['alert_threshold_pct']!, _alertThresholdPctMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryBudget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryBudget(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      yearMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year_month'])!,
      limitVnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}limit_vnd'])!,
      alertThresholdPct: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}alert_threshold_pct'])!,
    );
  }

  @override
  $CategoryBudgetsTable createAlias(String alias) {
    return $CategoryBudgetsTable(attachedDatabase, alias);
  }
}

class CategoryBudget extends DataClass implements Insertable<CategoryBudget> {
  final int id;
  final int categoryId;
  final int yearMonth;
  final int limitVnd;
  final int alertThresholdPct;
  const CategoryBudget(
      {required this.id,
      required this.categoryId,
      required this.yearMonth,
      required this.limitVnd,
      required this.alertThresholdPct});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['year_month'] = Variable<int>(yearMonth);
    map['limit_vnd'] = Variable<int>(limitVnd);
    map['alert_threshold_pct'] = Variable<int>(alertThresholdPct);
    return map;
  }

  CategoryBudgetsCompanion toCompanion(bool nullToAbsent) {
    return CategoryBudgetsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      yearMonth: Value(yearMonth),
      limitVnd: Value(limitVnd),
      alertThresholdPct: Value(alertThresholdPct),
    );
  }

  factory CategoryBudget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryBudget(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      yearMonth: serializer.fromJson<int>(json['yearMonth']),
      limitVnd: serializer.fromJson<int>(json['limitVnd']),
      alertThresholdPct: serializer.fromJson<int>(json['alertThresholdPct']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'yearMonth': serializer.toJson<int>(yearMonth),
      'limitVnd': serializer.toJson<int>(limitVnd),
      'alertThresholdPct': serializer.toJson<int>(alertThresholdPct),
    };
  }

  CategoryBudget copyWith(
          {int? id,
          int? categoryId,
          int? yearMonth,
          int? limitVnd,
          int? alertThresholdPct}) =>
      CategoryBudget(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        yearMonth: yearMonth ?? this.yearMonth,
        limitVnd: limitVnd ?? this.limitVnd,
        alertThresholdPct: alertThresholdPct ?? this.alertThresholdPct,
      );
  CategoryBudget copyWithCompanion(CategoryBudgetsCompanion data) {
    return CategoryBudget(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      yearMonth: data.yearMonth.present ? data.yearMonth.value : this.yearMonth,
      limitVnd: data.limitVnd.present ? data.limitVnd.value : this.limitVnd,
      alertThresholdPct: data.alertThresholdPct.present
          ? data.alertThresholdPct.value
          : this.alertThresholdPct,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryBudget(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('limitVnd: $limitVnd, ')
          ..write('alertThresholdPct: $alertThresholdPct')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, categoryId, yearMonth, limitVnd, alertThresholdPct);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryBudget &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.yearMonth == this.yearMonth &&
          other.limitVnd == this.limitVnd &&
          other.alertThresholdPct == this.alertThresholdPct);
}

class CategoryBudgetsCompanion extends UpdateCompanion<CategoryBudget> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<int> yearMonth;
  final Value<int> limitVnd;
  final Value<int> alertThresholdPct;
  const CategoryBudgetsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.yearMonth = const Value.absent(),
    this.limitVnd = const Value.absent(),
    this.alertThresholdPct = const Value.absent(),
  });
  CategoryBudgetsCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required int yearMonth,
    required int limitVnd,
    this.alertThresholdPct = const Value.absent(),
  })  : categoryId = Value(categoryId),
        yearMonth = Value(yearMonth),
        limitVnd = Value(limitVnd);
  static Insertable<CategoryBudget> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<int>? yearMonth,
    Expression<int>? limitVnd,
    Expression<int>? alertThresholdPct,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (yearMonth != null) 'year_month': yearMonth,
      if (limitVnd != null) 'limit_vnd': limitVnd,
      if (alertThresholdPct != null) 'alert_threshold_pct': alertThresholdPct,
    });
  }

  CategoryBudgetsCompanion copyWith(
      {Value<int>? id,
      Value<int>? categoryId,
      Value<int>? yearMonth,
      Value<int>? limitVnd,
      Value<int>? alertThresholdPct}) {
    return CategoryBudgetsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      yearMonth: yearMonth ?? this.yearMonth,
      limitVnd: limitVnd ?? this.limitVnd,
      alertThresholdPct: alertThresholdPct ?? this.alertThresholdPct,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (yearMonth.present) {
      map['year_month'] = Variable<int>(yearMonth.value);
    }
    if (limitVnd.present) {
      map['limit_vnd'] = Variable<int>(limitVnd.value);
    }
    if (alertThresholdPct.present) {
      map['alert_threshold_pct'] = Variable<int>(alertThresholdPct.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryBudgetsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('limitVnd: $limitVnd, ')
          ..write('alertThresholdPct: $alertThresholdPct')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _minimumCashBufferVndMeta =
      const VerificationMeta('minimumCashBufferVnd');
  @override
  late final GeneratedColumn<int> minimumCashBufferVnd = GeneratedColumn<int>(
      'minimum_cash_buffer_vnd', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _periodStartDayMeta =
      const VerificationMeta('periodStartDay');
  @override
  late final GeneratedColumn<int> periodStartDay = GeneratedColumn<int>(
      'period_start_day', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _dailyReminderHourMeta =
      const VerificationMeta('dailyReminderHour');
  @override
  late final GeneratedColumn<int> dailyReminderHour = GeneratedColumn<int>(
      'daily_reminder_hour', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(20));
  static const VerificationMeta _dailyReminderMinuteMeta =
      const VerificationMeta('dailyReminderMinute');
  @override
  late final GeneratedColumn<int> dailyReminderMinute = GeneratedColumn<int>(
      'daily_reminder_minute', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
      'notifications_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notifications_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _schemaVersionMeta =
      const VerificationMeta('schemaVersion');
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
      'schema_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        minimumCashBufferVnd,
        periodStartDay,
        dailyReminderHour,
        dailyReminderMinute,
        notificationsEnabled,
        schemaVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('minimum_cash_buffer_vnd')) {
      context.handle(
          _minimumCashBufferVndMeta,
          minimumCashBufferVnd.isAcceptableOrUnknown(
              data['minimum_cash_buffer_vnd']!, _minimumCashBufferVndMeta));
    }
    if (data.containsKey('period_start_day')) {
      context.handle(
          _periodStartDayMeta,
          periodStartDay.isAcceptableOrUnknown(
              data['period_start_day']!, _periodStartDayMeta));
    }
    if (data.containsKey('daily_reminder_hour')) {
      context.handle(
          _dailyReminderHourMeta,
          dailyReminderHour.isAcceptableOrUnknown(
              data['daily_reminder_hour']!, _dailyReminderHourMeta));
    }
    if (data.containsKey('daily_reminder_minute')) {
      context.handle(
          _dailyReminderMinuteMeta,
          dailyReminderMinute.isAcceptableOrUnknown(
              data['daily_reminder_minute']!, _dailyReminderMinuteMeta));
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
          _notificationsEnabledMeta,
          notificationsEnabled.isAcceptableOrUnknown(
              data['notifications_enabled']!, _notificationsEnabledMeta));
    }
    if (data.containsKey('schema_version')) {
      context.handle(
          _schemaVersionMeta,
          schemaVersion.isAcceptableOrUnknown(
              data['schema_version']!, _schemaVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      minimumCashBufferVnd: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}minimum_cash_buffer_vnd'])!,
      periodStartDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period_start_day'])!,
      dailyReminderHour: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}daily_reminder_hour'])!,
      dailyReminderMinute: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}daily_reminder_minute'])!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}notifications_enabled'])!,
      schemaVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}schema_version'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final int minimumCashBufferVnd;
  final int periodStartDay;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final bool notificationsEnabled;
  final int schemaVersion;
  const Setting(
      {required this.id,
      required this.minimumCashBufferVnd,
      required this.periodStartDay,
      required this.dailyReminderHour,
      required this.dailyReminderMinute,
      required this.notificationsEnabled,
      required this.schemaVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['minimum_cash_buffer_vnd'] = Variable<int>(minimumCashBufferVnd);
    map['period_start_day'] = Variable<int>(periodStartDay);
    map['daily_reminder_hour'] = Variable<int>(dailyReminderHour);
    map['daily_reminder_minute'] = Variable<int>(dailyReminderMinute);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      minimumCashBufferVnd: Value(minimumCashBufferVnd),
      periodStartDay: Value(periodStartDay),
      dailyReminderHour: Value(dailyReminderHour),
      dailyReminderMinute: Value(dailyReminderMinute),
      notificationsEnabled: Value(notificationsEnabled),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      minimumCashBufferVnd:
          serializer.fromJson<int>(json['minimumCashBufferVnd']),
      periodStartDay: serializer.fromJson<int>(json['periodStartDay']),
      dailyReminderHour: serializer.fromJson<int>(json['dailyReminderHour']),
      dailyReminderMinute:
          serializer.fromJson<int>(json['dailyReminderMinute']),
      notificationsEnabled:
          serializer.fromJson<bool>(json['notificationsEnabled']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'minimumCashBufferVnd': serializer.toJson<int>(minimumCashBufferVnd),
      'periodStartDay': serializer.toJson<int>(periodStartDay),
      'dailyReminderHour': serializer.toJson<int>(dailyReminderHour),
      'dailyReminderMinute': serializer.toJson<int>(dailyReminderMinute),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  Setting copyWith(
          {int? id,
          int? minimumCashBufferVnd,
          int? periodStartDay,
          int? dailyReminderHour,
          int? dailyReminderMinute,
          bool? notificationsEnabled,
          int? schemaVersion}) =>
      Setting(
        id: id ?? this.id,
        minimumCashBufferVnd: minimumCashBufferVnd ?? this.minimumCashBufferVnd,
        periodStartDay: periodStartDay ?? this.periodStartDay,
        dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
        dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        schemaVersion: schemaVersion ?? this.schemaVersion,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      minimumCashBufferVnd: data.minimumCashBufferVnd.present
          ? data.minimumCashBufferVnd.value
          : this.minimumCashBufferVnd,
      periodStartDay: data.periodStartDay.present
          ? data.periodStartDay.value
          : this.periodStartDay,
      dailyReminderHour: data.dailyReminderHour.present
          ? data.dailyReminderHour.value
          : this.dailyReminderHour,
      dailyReminderMinute: data.dailyReminderMinute.present
          ? data.dailyReminderMinute.value
          : this.dailyReminderMinute,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('minimumCashBufferVnd: $minimumCashBufferVnd, ')
          ..write('periodStartDay: $periodStartDay, ')
          ..write('dailyReminderHour: $dailyReminderHour, ')
          ..write('dailyReminderMinute: $dailyReminderMinute, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      minimumCashBufferVnd,
      periodStartDay,
      dailyReminderHour,
      dailyReminderMinute,
      notificationsEnabled,
      schemaVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.minimumCashBufferVnd == this.minimumCashBufferVnd &&
          other.periodStartDay == this.periodStartDay &&
          other.dailyReminderHour == this.dailyReminderHour &&
          other.dailyReminderMinute == this.dailyReminderMinute &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.schemaVersion == this.schemaVersion);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<int> minimumCashBufferVnd;
  final Value<int> periodStartDay;
  final Value<int> dailyReminderHour;
  final Value<int> dailyReminderMinute;
  final Value<bool> notificationsEnabled;
  final Value<int> schemaVersion;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.minimumCashBufferVnd = const Value.absent(),
    this.periodStartDay = const Value.absent(),
    this.dailyReminderHour = const Value.absent(),
    this.dailyReminderMinute = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.schemaVersion = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.minimumCashBufferVnd = const Value.absent(),
    this.periodStartDay = const Value.absent(),
    this.dailyReminderHour = const Value.absent(),
    this.dailyReminderMinute = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.schemaVersion = const Value.absent(),
  });
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<int>? minimumCashBufferVnd,
    Expression<int>? periodStartDay,
    Expression<int>? dailyReminderHour,
    Expression<int>? dailyReminderMinute,
    Expression<bool>? notificationsEnabled,
    Expression<int>? schemaVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (minimumCashBufferVnd != null)
        'minimum_cash_buffer_vnd': minimumCashBufferVnd,
      if (periodStartDay != null) 'period_start_day': periodStartDay,
      if (dailyReminderHour != null) 'daily_reminder_hour': dailyReminderHour,
      if (dailyReminderMinute != null)
        'daily_reminder_minute': dailyReminderMinute,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (schemaVersion != null) 'schema_version': schemaVersion,
    });
  }

  SettingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? minimumCashBufferVnd,
      Value<int>? periodStartDay,
      Value<int>? dailyReminderHour,
      Value<int>? dailyReminderMinute,
      Value<bool>? notificationsEnabled,
      Value<int>? schemaVersion}) {
    return SettingsCompanion(
      id: id ?? this.id,
      minimumCashBufferVnd: minimumCashBufferVnd ?? this.minimumCashBufferVnd,
      periodStartDay: periodStartDay ?? this.periodStartDay,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (minimumCashBufferVnd.present) {
      map['minimum_cash_buffer_vnd'] =
          Variable<int>(minimumCashBufferVnd.value);
    }
    if (periodStartDay.present) {
      map['period_start_day'] = Variable<int>(periodStartDay.value);
    }
    if (dailyReminderHour.present) {
      map['daily_reminder_hour'] = Variable<int>(dailyReminderHour.value);
    }
    if (dailyReminderMinute.present) {
      map['daily_reminder_minute'] = Variable<int>(dailyReminderMinute.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('minimumCashBufferVnd: $minimumCashBufferVnd, ')
          ..write('periodStartDay: $periodStartDay, ')
          ..write('dailyReminderHour: $dailyReminderHour, ')
          ..write('dailyReminderMinute: $dailyReminderMinute, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LedgerAccountsTable ledgerAccounts = $LedgerAccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $JournalTransactionsTable journalTransactions =
      $JournalTransactionsTable(this);
  late final $EnvelopesTable envelopes = $EnvelopesTable(this);
  late final $JournalPostingsTable journalPostings =
      $JournalPostingsTable(this);
  late final $ScheduledItemsTable scheduledItems = $ScheduledItemsTable(this);
  late final $EnvelopeMovementsTable envelopeMovements =
      $EnvelopeMovementsTable(this);
  late final $CategoryBudgetsTable categoryBudgets =
      $CategoryBudgetsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index idxTxStatusType = Index('idx_tx_status_type',
      'CREATE INDEX idx_tx_status_type ON journal_transactions (status, tx_type)');
  late final Index idxTxOccurredAt = Index('idx_tx_occurred_at',
      'CREATE INDEX idx_tx_occurred_at ON journal_transactions (occurred_at)');
  late final Index idxPostingsTx = Index('idx_postings_tx',
      'CREATE INDEX idx_postings_tx ON journal_postings (transaction_id)');
  late final Index idxPostingsAcc = Index('idx_postings_acc',
      'CREATE INDEX idx_postings_acc ON journal_postings (account_id)');
  late final Index idxPostingsCat = Index('idx_postings_cat',
      'CREATE INDEX idx_postings_cat ON journal_postings (category_id)');
  late final Index idxPostingsEnv = Index('idx_postings_env',
      'CREATE INDEX idx_postings_env ON journal_postings (envelope_id)');
  late final Index idxMovementsSource = Index('idx_movements_source',
      'CREATE INDEX idx_movements_source ON envelope_movements (source_envelope_id)');
  late final Index idxMovementsDest = Index('idx_movements_dest',
      'CREATE INDEX idx_movements_dest ON envelope_movements (dest_envelope_id)');
  late final Index idxMovementsTx = Index('idx_movements_tx',
      'CREATE INDEX idx_movements_tx ON envelope_movements (linked_transaction_id)');
  late final Index idxCategoryBudgetsUnique = Index(
      'idx_category_budgets_unique',
      'CREATE UNIQUE INDEX idx_category_budgets_unique ON category_budgets (category_id, year_month)');
  late final Index idxScheduledDueStatus = Index('idx_scheduled_due_status',
      'CREATE INDEX idx_scheduled_due_status ON scheduled_items (due_date_ms, status)');
  late final LedgerDao ledgerDao = LedgerDao(this as AppDatabase);
  late final EnvelopeDao envelopeDao = EnvelopeDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        ledgerAccounts,
        categories,
        journalTransactions,
        envelopes,
        journalPostings,
        scheduledItems,
        envelopeMovements,
        categoryBudgets,
        settings,
        idxTxStatusType,
        idxTxOccurredAt,
        idxPostingsTx,
        idxPostingsAcc,
        idxPostingsCat,
        idxPostingsEnv,
        idxMovementsSource,
        idxMovementsDest,
        idxMovementsTx,
        idxCategoryBudgetsUnique,
        idxScheduledDueStatus
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('journal_transactions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('journal_transactions', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('journal_transactions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('journal_transactions', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('journal_transactions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('journal_postings', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('journal_postings', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('envelopes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('journal_postings', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('scheduled_items', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('envelopes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('scheduled_items', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('journal_transactions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('scheduled_items', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('journal_transactions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('envelope_movements', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('scheduled_items',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('envelope_movements', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('category_budgets', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$LedgerAccountsTableCreateCompanionBuilder = LedgerAccountsCompanion
    Function({
  Value<int> id,
  required String name,
  required String kind,
  Value<bool> isLiquid,
  Value<int> creditLimit,
  Value<bool> isArchived,
  required int createdAt,
});
typedef $$LedgerAccountsTableUpdateCompanionBuilder = LedgerAccountsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> kind,
  Value<bool> isLiquid,
  Value<int> creditLimit,
  Value<bool> isArchived,
  Value<int> createdAt,
});

final class $$LedgerAccountsTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerAccountsTable, LedgerAccount> {
  $$LedgerAccountsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CategoriesTable, List<Category>>
      _categoriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.categories,
              aliasName: $_aliasNameGenerator(
                  db.ledgerAccounts.id, db.categories.ledgerAccountId));

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.ledgerAccountId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$JournalPostingsTable, List<JournalPosting>>
      _journalPostingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.journalPostings,
              aliasName: $_aliasNameGenerator(
                  db.ledgerAccounts.id, db.journalPostings.accountId));

  $$JournalPostingsTableProcessedTableManager get journalPostingsRefs {
    final manager =
        $$JournalPostingsTableTableManager($_db, $_db.journalPostings)
            .filter((f) => f.accountId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_journalPostingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LedgerAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerAccountsTable> {
  $$LedgerAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLiquid => $composableBuilder(
      column: $table.isLiquid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> categoriesRefs(
      Expression<bool> Function($$CategoriesTableFilterComposer f) f) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.ledgerAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> journalPostingsRefs(
      Expression<bool> Function($$JournalPostingsTableFilterComposer f) f) {
    final $$JournalPostingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.journalPostings,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalPostingsTableFilterComposer(
              $db: $db,
              $table: $db.journalPostings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LedgerAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerAccountsTable> {
  $$LedgerAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLiquid => $composableBuilder(
      column: $table.isLiquid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LedgerAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerAccountsTable> {
  $$LedgerAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get isLiquid =>
      $composableBuilder(column: $table.isLiquid, builder: (column) => column);

  GeneratedColumn<int> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> categoriesRefs<T extends Object>(
      Expression<T> Function($$CategoriesTableAnnotationComposer a) f) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.ledgerAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> journalPostingsRefs<T extends Object>(
      Expression<T> Function($$JournalPostingsTableAnnotationComposer a) f) {
    final $$JournalPostingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.journalPostings,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalPostingsTableAnnotationComposer(
              $db: $db,
              $table: $db.journalPostings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LedgerAccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LedgerAccountsTable,
    LedgerAccount,
    $$LedgerAccountsTableFilterComposer,
    $$LedgerAccountsTableOrderingComposer,
    $$LedgerAccountsTableAnnotationComposer,
    $$LedgerAccountsTableCreateCompanionBuilder,
    $$LedgerAccountsTableUpdateCompanionBuilder,
    (LedgerAccount, $$LedgerAccountsTableReferences),
    LedgerAccount,
    PrefetchHooks Function({bool categoriesRefs, bool journalPostingsRefs})> {
  $$LedgerAccountsTableTableManager(
      _$AppDatabase db, $LedgerAccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<bool> isLiquid = const Value.absent(),
            Value<int> creditLimit = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              LedgerAccountsCompanion(
            id: id,
            name: name,
            kind: kind,
            isLiquid: isLiquid,
            creditLimit: creditLimit,
            isArchived: isArchived,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String kind,
            Value<bool> isLiquid = const Value.absent(),
            Value<int> creditLimit = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            required int createdAt,
          }) =>
              LedgerAccountsCompanion.insert(
            id: id,
            name: name,
            kind: kind,
            isLiquid: isLiquid,
            creditLimit: creditLimit,
            isArchived: isArchived,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LedgerAccountsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {categoriesRefs = false, journalPostingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (categoriesRefs) db.categories,
                if (journalPostingsRefs) db.journalPostings
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (categoriesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$LedgerAccountsTableReferences
                            ._categoriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LedgerAccountsTableReferences(db, table, p0)
                                .categoriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.ledgerAccountId == item.id),
                        typedResults: items),
                  if (journalPostingsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$LedgerAccountsTableReferences
                            ._journalPostingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LedgerAccountsTableReferences(db, table, p0)
                                .journalPostingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LedgerAccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LedgerAccountsTable,
    LedgerAccount,
    $$LedgerAccountsTableFilterComposer,
    $$LedgerAccountsTableOrderingComposer,
    $$LedgerAccountsTableAnnotationComposer,
    $$LedgerAccountsTableCreateCompanionBuilder,
    $$LedgerAccountsTableUpdateCompanionBuilder,
    (LedgerAccount, $$LedgerAccountsTableReferences),
    LedgerAccount,
    PrefetchHooks Function({bool categoriesRefs, bool journalPostingsRefs})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required String kind,
  required int ledgerAccountId,
  required int iconCode,
  required String colorHex,
  Value<bool> isDefault,
  Value<bool> isArchived,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> kind,
  Value<int> ledgerAccountId,
  Value<int> iconCode,
  Value<String> colorHex,
  Value<bool> isDefault,
  Value<bool> isArchived,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LedgerAccountsTable _ledgerAccountIdTable(_$AppDatabase db) =>
      db.ledgerAccounts.createAlias($_aliasNameGenerator(
          db.categories.ledgerAccountId, db.ledgerAccounts.id));

  $$LedgerAccountsTableProcessedTableManager get ledgerAccountId {
    final manager = $$LedgerAccountsTableTableManager($_db, $_db.ledgerAccounts)
        .filter((f) => f.id($_item.ledgerAccountId));
    final item = $_typedResult.readTableOrNull(_ledgerAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$JournalPostingsTable, List<JournalPosting>>
      _journalPostingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.journalPostings,
              aliasName: $_aliasNameGenerator(
                  db.categories.id, db.journalPostings.categoryId));

  $$JournalPostingsTableProcessedTableManager get journalPostingsRefs {
    final manager =
        $$JournalPostingsTableTableManager($_db, $_db.journalPostings)
            .filter((f) => f.categoryId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_journalPostingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ScheduledItemsTable, List<ScheduledItem>>
      _scheduledItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.scheduledItems,
              aliasName: $_aliasNameGenerator(
                  db.categories.id, db.scheduledItems.categoryId));

  $$ScheduledItemsTableProcessedTableManager get scheduledItemsRefs {
    final manager = $$ScheduledItemsTableTableManager($_db, $_db.scheduledItems)
        .filter((f) => f.categoryId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_scheduledItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CategoryBudgetsTable, List<CategoryBudget>>
      _categoryBudgetsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.categoryBudgets,
              aliasName: $_aliasNameGenerator(
                  db.categories.id, db.categoryBudgets.categoryId));

  $$CategoryBudgetsTableProcessedTableManager get categoryBudgetsRefs {
    final manager =
        $$CategoryBudgetsTableTableManager($_db, $_db.categoryBudgets)
            .filter((f) => f.categoryId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_categoryBudgetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get iconCode => $composableBuilder(
      column: $table.iconCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  $$LedgerAccountsTableFilterComposer get ledgerAccountId {
    final $$LedgerAccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ledgerAccountId,
        referencedTable: $db.ledgerAccounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LedgerAccountsTableFilterComposer(
              $db: $db,
              $table: $db.ledgerAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> journalPostingsRefs(
      Expression<bool> Function($$JournalPostingsTableFilterComposer f) f) {
    final $$JournalPostingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.journalPostings,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalPostingsTableFilterComposer(
              $db: $db,
              $table: $db.journalPostings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> scheduledItemsRefs(
      Expression<bool> Function($$ScheduledItemsTableFilterComposer f) f) {
    final $$ScheduledItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scheduledItems,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScheduledItemsTableFilterComposer(
              $db: $db,
              $table: $db.scheduledItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> categoryBudgetsRefs(
      Expression<bool> Function($$CategoryBudgetsTableFilterComposer f) f) {
    final $$CategoryBudgetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categoryBudgets,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoryBudgetsTableFilterComposer(
              $db: $db,
              $table: $db.categoryBudgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get iconCode => $composableBuilder(
      column: $table.iconCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  $$LedgerAccountsTableOrderingComposer get ledgerAccountId {
    final $$LedgerAccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ledgerAccountId,
        referencedTable: $db.ledgerAccounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LedgerAccountsTableOrderingComposer(
              $db: $db,
              $table: $db.ledgerAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  $$LedgerAccountsTableAnnotationComposer get ledgerAccountId {
    final $$LedgerAccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ledgerAccountId,
        referencedTable: $db.ledgerAccounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LedgerAccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.ledgerAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> journalPostingsRefs<T extends Object>(
      Expression<T> Function($$JournalPostingsTableAnnotationComposer a) f) {
    final $$JournalPostingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.journalPostings,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalPostingsTableAnnotationComposer(
              $db: $db,
              $table: $db.journalPostings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> scheduledItemsRefs<T extends Object>(
      Expression<T> Function($$ScheduledItemsTableAnnotationComposer a) f) {
    final $$ScheduledItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scheduledItems,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScheduledItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.scheduledItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> categoryBudgetsRefs<T extends Object>(
      Expression<T> Function($$CategoryBudgetsTableAnnotationComposer a) f) {
    final $$CategoryBudgetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categoryBudgets,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoryBudgetsTableAnnotationComposer(
              $db: $db,
              $table: $db.categoryBudgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function(
        {bool ledgerAccountId,
        bool journalPostingsRefs,
        bool scheduledItemsRefs,
        bool categoryBudgetsRefs})> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> ledgerAccountId = const Value.absent(),
            Value<int> iconCode = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            kind: kind,
            ledgerAccountId: ledgerAccountId,
            iconCode: iconCode,
            colorHex: colorHex,
            isDefault: isDefault,
            isArchived: isArchived,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String kind,
            required int ledgerAccountId,
            required int iconCode,
            required String colorHex,
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            kind: kind,
            ledgerAccountId: ledgerAccountId,
            iconCode: iconCode,
            colorHex: colorHex,
            isDefault: isDefault,
            isArchived: isArchived,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {ledgerAccountId = false,
              journalPostingsRefs = false,
              scheduledItemsRefs = false,
              categoryBudgetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (journalPostingsRefs) db.journalPostings,
                if (scheduledItemsRefs) db.scheduledItems,
                if (categoryBudgetsRefs) db.categoryBudgets
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (ledgerAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ledgerAccountId,
                    referencedTable:
                        $$CategoriesTableReferences._ledgerAccountIdTable(db),
                    referencedColumn: $$CategoriesTableReferences
                        ._ledgerAccountIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (journalPostingsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._journalPostingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .journalPostingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (scheduledItemsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._scheduledItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .scheduledItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (categoryBudgetsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._categoryBudgetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .categoryBudgetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function(
        {bool ledgerAccountId,
        bool journalPostingsRefs,
        bool scheduledItemsRefs,
        bool categoryBudgetsRefs})>;
typedef $$JournalTransactionsTableCreateCompanionBuilder
    = JournalTransactionsCompanion Function({
  Value<int> id,
  required String txType,
  Value<String> status,
  Value<String> description,
  required int occurredAt,
  required int createdAt,
  Value<String?> idempotencyKey,
  Value<int?> reversesTxId,
  Value<int?> replacedByTxId,
});
typedef $$JournalTransactionsTableUpdateCompanionBuilder
    = JournalTransactionsCompanion Function({
  Value<int> id,
  Value<String> txType,
  Value<String> status,
  Value<String> description,
  Value<int> occurredAt,
  Value<int> createdAt,
  Value<String?> idempotencyKey,
  Value<int?> reversesTxId,
  Value<int?> replacedByTxId,
});

final class $$JournalTransactionsTableReferences extends BaseReferences<
    _$AppDatabase, $JournalTransactionsTable, JournalTransaction> {
  $$JournalTransactionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $JournalTransactionsTable _reversesTxIdTable(_$AppDatabase db) =>
      db.journalTransactions.createAlias($_aliasNameGenerator(
          db.journalTransactions.reversesTxId, db.journalTransactions.id));

  $$JournalTransactionsTableProcessedTableManager? get reversesTxId {
    if ($_item.reversesTxId == null) return null;
    final manager =
        $$JournalTransactionsTableTableManager($_db, $_db.journalTransactions)
            .filter((f) => f.id($_item.reversesTxId!));
    final item = $_typedResult.readTableOrNull(_reversesTxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $JournalTransactionsTable _replacedByTxIdTable(_$AppDatabase db) =>
      db.journalTransactions.createAlias($_aliasNameGenerator(
          db.journalTransactions.replacedByTxId, db.journalTransactions.id));

  $$JournalTransactionsTableProcessedTableManager? get replacedByTxId {
    if ($_item.replacedByTxId == null) return null;
    final manager =
        $$JournalTransactionsTableTableManager($_db, $_db.journalTransactions)
            .filter((f) => f.id($_item.replacedByTxId!));
    final item = $_typedResult.readTableOrNull(_replacedByTxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$JournalPostingsTable, List<JournalPosting>>
      _journalPostingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.journalPostings,
              aliasName: $_aliasNameGenerator(
                  db.journalTransactions.id, db.journalPostings.transactionId));

  $$JournalPostingsTableProcessedTableManager get journalPostingsRefs {
    final manager =
        $$JournalPostingsTableTableManager($_db, $_db.journalPostings)
            .filter((f) => f.transactionId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_journalPostingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ScheduledItemsTable, List<ScheduledItem>>
      _scheduledItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.scheduledItems,
              aliasName: $_aliasNameGenerator(db.journalTransactions.id,
                  db.scheduledItems.paidTransactionId));

  $$ScheduledItemsTableProcessedTableManager get scheduledItemsRefs {
    final manager = $$ScheduledItemsTableTableManager($_db, $_db.scheduledItems)
        .filter((f) => f.paidTransactionId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_scheduledItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EnvelopeMovementsTable, List<EnvelopeMovement>>
      _envelopeMovementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.envelopeMovements,
              aliasName: $_aliasNameGenerator(db.journalTransactions.id,
                  db.envelopeMovements.linkedTransactionId));

  $$EnvelopeMovementsTableProcessedTableManager get envelopeMovementsRefs {
    final manager =
        $$EnvelopeMovementsTableTableManager($_db, $_db.envelopeMovements)
            .filter((f) => f.linkedTransactionId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_envelopeMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$JournalTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $JournalTransactionsTable> {
  $$JournalTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get txType => $composableBuilder(
      column: $table.txType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnFilters(column));

  $$JournalTransactionsTableFilterComposer get reversesTxId {
    final $$JournalTransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.reversesTxId,
        referencedTable: $db.journalTransactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalTransactionsTableFilterComposer(
              $db: $db,
              $table: $db.journalTransactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$JournalTransactionsTableFilterComposer get replacedByTxId {
    final $$JournalTransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.replacedByTxId,
        referencedTable: $db.journalTransactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalTransactionsTableFilterComposer(
              $db: $db,
              $table: $db.journalTransactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> journalPostingsRefs(
      Expression<bool> Function($$JournalPostingsTableFilterComposer f) f) {
    final $$JournalPostingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.journalPostings,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalPostingsTableFilterComposer(
              $db: $db,
              $table: $db.journalPostings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> scheduledItemsRefs(
      Expression<bool> Function($$ScheduledItemsTableFilterComposer f) f) {
    final $$ScheduledItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scheduledItems,
        getReferencedColumn: (t) => t.paidTransactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScheduledItemsTableFilterComposer(
              $db: $db,
              $table: $db.scheduledItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> envelopeMovementsRefs(
      Expression<bool> Function($$EnvelopeMovementsTableFilterComposer f) f) {
    final $$EnvelopeMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.envelopeMovements,
        getReferencedColumn: (t) => t.linkedTransactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopeMovementsTableFilterComposer(
              $db: $db,
              $table: $db.envelopeMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$JournalTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalTransactionsTable> {
  $$JournalTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get txType => $composableBuilder(
      column: $table.txType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnOrderings(column));

  $$JournalTransactionsTableOrderingComposer get reversesTxId {
    final $$JournalTransactionsTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.reversesTxId,
            referencedTable: $db.journalTransactions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$JournalTransactionsTableOrderingComposer(
                  $db: $db,
                  $table: $db.journalTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$JournalTransactionsTableOrderingComposer get replacedByTxId {
    final $$JournalTransactionsTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.replacedByTxId,
            referencedTable: $db.journalTransactions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$JournalTransactionsTableOrderingComposer(
                  $db: $db,
                  $table: $db.journalTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$JournalTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalTransactionsTable> {
  $$JournalTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get txType =>
      $composableBuilder(column: $table.txType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey, builder: (column) => column);

  $$JournalTransactionsTableAnnotationComposer get reversesTxId {
    final $$JournalTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.reversesTxId,
            referencedTable: $db.journalTransactions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$JournalTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.journalTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$JournalTransactionsTableAnnotationComposer get replacedByTxId {
    final $$JournalTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.replacedByTxId,
            referencedTable: $db.journalTransactions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$JournalTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.journalTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  Expression<T> journalPostingsRefs<T extends Object>(
      Expression<T> Function($$JournalPostingsTableAnnotationComposer a) f) {
    final $$JournalPostingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.journalPostings,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalPostingsTableAnnotationComposer(
              $db: $db,
              $table: $db.journalPostings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> scheduledItemsRefs<T extends Object>(
      Expression<T> Function($$ScheduledItemsTableAnnotationComposer a) f) {
    final $$ScheduledItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scheduledItems,
        getReferencedColumn: (t) => t.paidTransactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScheduledItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.scheduledItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> envelopeMovementsRefs<T extends Object>(
      Expression<T> Function($$EnvelopeMovementsTableAnnotationComposer a) f) {
    final $$EnvelopeMovementsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.envelopeMovements,
            getReferencedColumn: (t) => t.linkedTransactionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$EnvelopeMovementsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.envelopeMovements,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$JournalTransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JournalTransactionsTable,
    JournalTransaction,
    $$JournalTransactionsTableFilterComposer,
    $$JournalTransactionsTableOrderingComposer,
    $$JournalTransactionsTableAnnotationComposer,
    $$JournalTransactionsTableCreateCompanionBuilder,
    $$JournalTransactionsTableUpdateCompanionBuilder,
    (JournalTransaction, $$JournalTransactionsTableReferences),
    JournalTransaction,
    PrefetchHooks Function(
        {bool reversesTxId,
        bool replacedByTxId,
        bool journalPostingsRefs,
        bool scheduledItemsRefs,
        bool envelopeMovementsRefs})> {
  $$JournalTransactionsTableTableManager(
      _$AppDatabase db, $JournalTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalTransactionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> txType = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<int> occurredAt = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<String?> idempotencyKey = const Value.absent(),
            Value<int?> reversesTxId = const Value.absent(),
            Value<int?> replacedByTxId = const Value.absent(),
          }) =>
              JournalTransactionsCompanion(
            id: id,
            txType: txType,
            status: status,
            description: description,
            occurredAt: occurredAt,
            createdAt: createdAt,
            idempotencyKey: idempotencyKey,
            reversesTxId: reversesTxId,
            replacedByTxId: replacedByTxId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String txType,
            Value<String> status = const Value.absent(),
            Value<String> description = const Value.absent(),
            required int occurredAt,
            required int createdAt,
            Value<String?> idempotencyKey = const Value.absent(),
            Value<int?> reversesTxId = const Value.absent(),
            Value<int?> replacedByTxId = const Value.absent(),
          }) =>
              JournalTransactionsCompanion.insert(
            id: id,
            txType: txType,
            status: status,
            description: description,
            occurredAt: occurredAt,
            createdAt: createdAt,
            idempotencyKey: idempotencyKey,
            reversesTxId: reversesTxId,
            replacedByTxId: replacedByTxId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$JournalTransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {reversesTxId = false,
              replacedByTxId = false,
              journalPostingsRefs = false,
              scheduledItemsRefs = false,
              envelopeMovementsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (journalPostingsRefs) db.journalPostings,
                if (scheduledItemsRefs) db.scheduledItems,
                if (envelopeMovementsRefs) db.envelopeMovements
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (reversesTxId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.reversesTxId,
                    referencedTable: $$JournalTransactionsTableReferences
                        ._reversesTxIdTable(db),
                    referencedColumn: $$JournalTransactionsTableReferences
                        ._reversesTxIdTable(db)
                        .id,
                  ) as T;
                }
                if (replacedByTxId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.replacedByTxId,
                    referencedTable: $$JournalTransactionsTableReferences
                        ._replacedByTxIdTable(db),
                    referencedColumn: $$JournalTransactionsTableReferences
                        ._replacedByTxIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (journalPostingsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$JournalTransactionsTableReferences
                            ._journalPostingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$JournalTransactionsTableReferences(db, table, p0)
                                .journalPostingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.transactionId == item.id),
                        typedResults: items),
                  if (scheduledItemsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$JournalTransactionsTableReferences
                            ._scheduledItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$JournalTransactionsTableReferences(db, table, p0)
                                .scheduledItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.paidTransactionId == item.id),
                        typedResults: items),
                  if (envelopeMovementsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$JournalTransactionsTableReferences
                            ._envelopeMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$JournalTransactionsTableReferences(db, table, p0)
                                .envelopeMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.linkedTransactionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$JournalTransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $JournalTransactionsTable,
    JournalTransaction,
    $$JournalTransactionsTableFilterComposer,
    $$JournalTransactionsTableOrderingComposer,
    $$JournalTransactionsTableAnnotationComposer,
    $$JournalTransactionsTableCreateCompanionBuilder,
    $$JournalTransactionsTableUpdateCompanionBuilder,
    (JournalTransaction, $$JournalTransactionsTableReferences),
    JournalTransaction,
    PrefetchHooks Function(
        {bool reversesTxId,
        bool replacedByTxId,
        bool journalPostingsRefs,
        bool scheduledItemsRefs,
        bool envelopeMovementsRefs})>;
typedef $$EnvelopesTableCreateCompanionBuilder = EnvelopesCompanion Function({
  Value<int> id,
  required String name,
  required String policy,
  Value<int> reservedBalanceVnd,
  Value<bool> allowNegativeException,
  Value<int?> targetAmountVnd,
  Value<int?> targetDateMs,
  Value<int?> periodLimitVnd,
  Value<bool> rolloverEnabled,
  Value<int> priority,
  Value<bool> isArchived,
});
typedef $$EnvelopesTableUpdateCompanionBuilder = EnvelopesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> policy,
  Value<int> reservedBalanceVnd,
  Value<bool> allowNegativeException,
  Value<int?> targetAmountVnd,
  Value<int?> targetDateMs,
  Value<int?> periodLimitVnd,
  Value<bool> rolloverEnabled,
  Value<int> priority,
  Value<bool> isArchived,
});

final class $$EnvelopesTableReferences
    extends BaseReferences<_$AppDatabase, $EnvelopesTable, Envelope> {
  $$EnvelopesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$JournalPostingsTable, List<JournalPosting>>
      _journalPostingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.journalPostings,
              aliasName: $_aliasNameGenerator(
                  db.envelopes.id, db.journalPostings.envelopeId));

  $$JournalPostingsTableProcessedTableManager get journalPostingsRefs {
    final manager =
        $$JournalPostingsTableTableManager($_db, $_db.journalPostings)
            .filter((f) => f.envelopeId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_journalPostingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ScheduledItemsTable, List<ScheduledItem>>
      _scheduledItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.scheduledItems,
              aliasName: $_aliasNameGenerator(
                  db.envelopes.id, db.scheduledItems.linkedEnvelopeId));

  $$ScheduledItemsTableProcessedTableManager get scheduledItemsRefs {
    final manager = $$ScheduledItemsTableTableManager($_db, $_db.scheduledItems)
        .filter((f) => f.linkedEnvelopeId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_scheduledItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EnvelopeMovementsTable, List<EnvelopeMovement>>
      _sourceEnvelopeMovementsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.envelopeMovements,
              aliasName: $_aliasNameGenerator(
                  db.envelopes.id, db.envelopeMovements.sourceEnvelopeId));

  $$EnvelopeMovementsTableProcessedTableManager get sourceEnvelopeMovements {
    final manager =
        $$EnvelopeMovementsTableTableManager($_db, $_db.envelopeMovements)
            .filter((f) => f.sourceEnvelopeId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_sourceEnvelopeMovementsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EnvelopeMovementsTable, List<EnvelopeMovement>>
      _destEnvelopeMovementsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.envelopeMovements,
              aliasName: $_aliasNameGenerator(
                  db.envelopes.id, db.envelopeMovements.destEnvelopeId));

  $$EnvelopeMovementsTableProcessedTableManager get destEnvelopeMovements {
    final manager =
        $$EnvelopeMovementsTableTableManager($_db, $_db.envelopeMovements)
            .filter((f) => f.destEnvelopeId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_destEnvelopeMovementsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EnvelopesTableFilterComposer
    extends Composer<_$AppDatabase, $EnvelopesTable> {
  $$EnvelopesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get policy => $composableBuilder(
      column: $table.policy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reservedBalanceVnd => $composableBuilder(
      column: $table.reservedBalanceVnd,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allowNegativeException => $composableBuilder(
      column: $table.allowNegativeException,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetAmountVnd => $composableBuilder(
      column: $table.targetAmountVnd,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetDateMs => $composableBuilder(
      column: $table.targetDateMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get periodLimitVnd => $composableBuilder(
      column: $table.periodLimitVnd,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get rolloverEnabled => $composableBuilder(
      column: $table.rolloverEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  Expression<bool> journalPostingsRefs(
      Expression<bool> Function($$JournalPostingsTableFilterComposer f) f) {
    final $$JournalPostingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.journalPostings,
        getReferencedColumn: (t) => t.envelopeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalPostingsTableFilterComposer(
              $db: $db,
              $table: $db.journalPostings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> scheduledItemsRefs(
      Expression<bool> Function($$ScheduledItemsTableFilterComposer f) f) {
    final $$ScheduledItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scheduledItems,
        getReferencedColumn: (t) => t.linkedEnvelopeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScheduledItemsTableFilterComposer(
              $db: $db,
              $table: $db.scheduledItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> sourceEnvelopeMovements(
      Expression<bool> Function($$EnvelopeMovementsTableFilterComposer f) f) {
    final $$EnvelopeMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.envelopeMovements,
        getReferencedColumn: (t) => t.sourceEnvelopeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopeMovementsTableFilterComposer(
              $db: $db,
              $table: $db.envelopeMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> destEnvelopeMovements(
      Expression<bool> Function($$EnvelopeMovementsTableFilterComposer f) f) {
    final $$EnvelopeMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.envelopeMovements,
        getReferencedColumn: (t) => t.destEnvelopeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopeMovementsTableFilterComposer(
              $db: $db,
              $table: $db.envelopeMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EnvelopesTableOrderingComposer
    extends Composer<_$AppDatabase, $EnvelopesTable> {
  $$EnvelopesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get policy => $composableBuilder(
      column: $table.policy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reservedBalanceVnd => $composableBuilder(
      column: $table.reservedBalanceVnd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allowNegativeException => $composableBuilder(
      column: $table.allowNegativeException,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetAmountVnd => $composableBuilder(
      column: $table.targetAmountVnd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetDateMs => $composableBuilder(
      column: $table.targetDateMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get periodLimitVnd => $composableBuilder(
      column: $table.periodLimitVnd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get rolloverEnabled => $composableBuilder(
      column: $table.rolloverEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));
}

class $$EnvelopesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnvelopesTable> {
  $$EnvelopesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get policy =>
      $composableBuilder(column: $table.policy, builder: (column) => column);

  GeneratedColumn<int> get reservedBalanceVnd => $composableBuilder(
      column: $table.reservedBalanceVnd, builder: (column) => column);

  GeneratedColumn<bool> get allowNegativeException => $composableBuilder(
      column: $table.allowNegativeException, builder: (column) => column);

  GeneratedColumn<int> get targetAmountVnd => $composableBuilder(
      column: $table.targetAmountVnd, builder: (column) => column);

  GeneratedColumn<int> get targetDateMs => $composableBuilder(
      column: $table.targetDateMs, builder: (column) => column);

  GeneratedColumn<int> get periodLimitVnd => $composableBuilder(
      column: $table.periodLimitVnd, builder: (column) => column);

  GeneratedColumn<bool> get rolloverEnabled => $composableBuilder(
      column: $table.rolloverEnabled, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  Expression<T> journalPostingsRefs<T extends Object>(
      Expression<T> Function($$JournalPostingsTableAnnotationComposer a) f) {
    final $$JournalPostingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.journalPostings,
        getReferencedColumn: (t) => t.envelopeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalPostingsTableAnnotationComposer(
              $db: $db,
              $table: $db.journalPostings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> scheduledItemsRefs<T extends Object>(
      Expression<T> Function($$ScheduledItemsTableAnnotationComposer a) f) {
    final $$ScheduledItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scheduledItems,
        getReferencedColumn: (t) => t.linkedEnvelopeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScheduledItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.scheduledItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> sourceEnvelopeMovements<T extends Object>(
      Expression<T> Function($$EnvelopeMovementsTableAnnotationComposer a) f) {
    final $$EnvelopeMovementsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.envelopeMovements,
            getReferencedColumn: (t) => t.sourceEnvelopeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$EnvelopeMovementsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.envelopeMovements,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> destEnvelopeMovements<T extends Object>(
      Expression<T> Function($$EnvelopeMovementsTableAnnotationComposer a) f) {
    final $$EnvelopeMovementsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.envelopeMovements,
            getReferencedColumn: (t) => t.destEnvelopeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$EnvelopeMovementsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.envelopeMovements,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$EnvelopesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EnvelopesTable,
    Envelope,
    $$EnvelopesTableFilterComposer,
    $$EnvelopesTableOrderingComposer,
    $$EnvelopesTableAnnotationComposer,
    $$EnvelopesTableCreateCompanionBuilder,
    $$EnvelopesTableUpdateCompanionBuilder,
    (Envelope, $$EnvelopesTableReferences),
    Envelope,
    PrefetchHooks Function(
        {bool journalPostingsRefs,
        bool scheduledItemsRefs,
        bool sourceEnvelopeMovements,
        bool destEnvelopeMovements})> {
  $$EnvelopesTableTableManager(_$AppDatabase db, $EnvelopesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvelopesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnvelopesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnvelopesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> policy = const Value.absent(),
            Value<int> reservedBalanceVnd = const Value.absent(),
            Value<bool> allowNegativeException = const Value.absent(),
            Value<int?> targetAmountVnd = const Value.absent(),
            Value<int?> targetDateMs = const Value.absent(),
            Value<int?> periodLimitVnd = const Value.absent(),
            Value<bool> rolloverEnabled = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
          }) =>
              EnvelopesCompanion(
            id: id,
            name: name,
            policy: policy,
            reservedBalanceVnd: reservedBalanceVnd,
            allowNegativeException: allowNegativeException,
            targetAmountVnd: targetAmountVnd,
            targetDateMs: targetDateMs,
            periodLimitVnd: periodLimitVnd,
            rolloverEnabled: rolloverEnabled,
            priority: priority,
            isArchived: isArchived,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String policy,
            Value<int> reservedBalanceVnd = const Value.absent(),
            Value<bool> allowNegativeException = const Value.absent(),
            Value<int?> targetAmountVnd = const Value.absent(),
            Value<int?> targetDateMs = const Value.absent(),
            Value<int?> periodLimitVnd = const Value.absent(),
            Value<bool> rolloverEnabled = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
          }) =>
              EnvelopesCompanion.insert(
            id: id,
            name: name,
            policy: policy,
            reservedBalanceVnd: reservedBalanceVnd,
            allowNegativeException: allowNegativeException,
            targetAmountVnd: targetAmountVnd,
            targetDateMs: targetDateMs,
            periodLimitVnd: periodLimitVnd,
            rolloverEnabled: rolloverEnabled,
            priority: priority,
            isArchived: isArchived,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EnvelopesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {journalPostingsRefs = false,
              scheduledItemsRefs = false,
              sourceEnvelopeMovements = false,
              destEnvelopeMovements = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (journalPostingsRefs) db.journalPostings,
                if (scheduledItemsRefs) db.scheduledItems,
                if (sourceEnvelopeMovements) db.envelopeMovements,
                if (destEnvelopeMovements) db.envelopeMovements
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (journalPostingsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$EnvelopesTableReferences
                            ._journalPostingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EnvelopesTableReferences(db, table, p0)
                                .journalPostingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.envelopeId == item.id),
                        typedResults: items),
                  if (scheduledItemsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$EnvelopesTableReferences
                            ._scheduledItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EnvelopesTableReferences(db, table, p0)
                                .scheduledItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.linkedEnvelopeId == item.id),
                        typedResults: items),
                  if (sourceEnvelopeMovements)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$EnvelopesTableReferences
                            ._sourceEnvelopeMovementsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EnvelopesTableReferences(db, table, p0)
                                .sourceEnvelopeMovements,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sourceEnvelopeId == item.id),
                        typedResults: items),
                  if (destEnvelopeMovements)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$EnvelopesTableReferences
                            ._destEnvelopeMovementsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EnvelopesTableReferences(db, table, p0)
                                .destEnvelopeMovements,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.destEnvelopeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EnvelopesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EnvelopesTable,
    Envelope,
    $$EnvelopesTableFilterComposer,
    $$EnvelopesTableOrderingComposer,
    $$EnvelopesTableAnnotationComposer,
    $$EnvelopesTableCreateCompanionBuilder,
    $$EnvelopesTableUpdateCompanionBuilder,
    (Envelope, $$EnvelopesTableReferences),
    Envelope,
    PrefetchHooks Function(
        {bool journalPostingsRefs,
        bool scheduledItemsRefs,
        bool sourceEnvelopeMovements,
        bool destEnvelopeMovements})>;
typedef $$JournalPostingsTableCreateCompanionBuilder = JournalPostingsCompanion
    Function({
  Value<int> id,
  required int transactionId,
  required int accountId,
  Value<int> debitVnd,
  Value<int> creditVnd,
  Value<int?> categoryId,
  Value<int?> envelopeId,
});
typedef $$JournalPostingsTableUpdateCompanionBuilder = JournalPostingsCompanion
    Function({
  Value<int> id,
  Value<int> transactionId,
  Value<int> accountId,
  Value<int> debitVnd,
  Value<int> creditVnd,
  Value<int?> categoryId,
  Value<int?> envelopeId,
});

final class $$JournalPostingsTableReferences extends BaseReferences<
    _$AppDatabase, $JournalPostingsTable, JournalPosting> {
  $$JournalPostingsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $JournalTransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.journalTransactions.createAlias($_aliasNameGenerator(
          db.journalPostings.transactionId, db.journalTransactions.id));

  $$JournalTransactionsTableProcessedTableManager get transactionId {
    final manager =
        $$JournalTransactionsTableTableManager($_db, $_db.journalTransactions)
            .filter((f) => f.id($_item.transactionId));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $LedgerAccountsTable _accountIdTable(_$AppDatabase db) =>
      db.ledgerAccounts.createAlias($_aliasNameGenerator(
          db.journalPostings.accountId, db.ledgerAccounts.id));

  $$LedgerAccountsTableProcessedTableManager get accountId {
    final manager = $$LedgerAccountsTableTableManager($_db, $_db.ledgerAccounts)
        .filter((f) => f.id($_item.accountId));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias($_aliasNameGenerator(
          db.journalPostings.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    if ($_item.categoryId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.categoryId!));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EnvelopesTable _envelopeIdTable(_$AppDatabase db) =>
      db.envelopes.createAlias(
          $_aliasNameGenerator(db.journalPostings.envelopeId, db.envelopes.id));

  $$EnvelopesTableProcessedTableManager? get envelopeId {
    if ($_item.envelopeId == null) return null;
    final manager = $$EnvelopesTableTableManager($_db, $_db.envelopes)
        .filter((f) => f.id($_item.envelopeId!));
    final item = $_typedResult.readTableOrNull(_envelopeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$JournalPostingsTableFilterComposer
    extends Composer<_$AppDatabase, $JournalPostingsTable> {
  $$JournalPostingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get debitVnd => $composableBuilder(
      column: $table.debitVnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get creditVnd => $composableBuilder(
      column: $table.creditVnd, builder: (column) => ColumnFilters(column));

  $$JournalTransactionsTableFilterComposer get transactionId {
    final $$JournalTransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.journalTransactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalTransactionsTableFilterComposer(
              $db: $db,
              $table: $db.journalTransactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LedgerAccountsTableFilterComposer get accountId {
    final $$LedgerAccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.ledgerAccounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LedgerAccountsTableFilterComposer(
              $db: $db,
              $table: $db.ledgerAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnvelopesTableFilterComposer get envelopeId {
    final $$EnvelopesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.envelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableFilterComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$JournalPostingsTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalPostingsTable> {
  $$JournalPostingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get debitVnd => $composableBuilder(
      column: $table.debitVnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get creditVnd => $composableBuilder(
      column: $table.creditVnd, builder: (column) => ColumnOrderings(column));

  $$JournalTransactionsTableOrderingComposer get transactionId {
    final $$JournalTransactionsTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.transactionId,
            referencedTable: $db.journalTransactions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$JournalTransactionsTableOrderingComposer(
                  $db: $db,
                  $table: $db.journalTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$LedgerAccountsTableOrderingComposer get accountId {
    final $$LedgerAccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.ledgerAccounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LedgerAccountsTableOrderingComposer(
              $db: $db,
              $table: $db.ledgerAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnvelopesTableOrderingComposer get envelopeId {
    final $$EnvelopesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.envelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableOrderingComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$JournalPostingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalPostingsTable> {
  $$JournalPostingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get debitVnd =>
      $composableBuilder(column: $table.debitVnd, builder: (column) => column);

  GeneratedColumn<int> get creditVnd =>
      $composableBuilder(column: $table.creditVnd, builder: (column) => column);

  $$JournalTransactionsTableAnnotationComposer get transactionId {
    final $$JournalTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.transactionId,
            referencedTable: $db.journalTransactions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$JournalTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.journalTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$LedgerAccountsTableAnnotationComposer get accountId {
    final $$LedgerAccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.ledgerAccounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LedgerAccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.ledgerAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnvelopesTableAnnotationComposer get envelopeId {
    final $$EnvelopesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.envelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableAnnotationComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$JournalPostingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JournalPostingsTable,
    JournalPosting,
    $$JournalPostingsTableFilterComposer,
    $$JournalPostingsTableOrderingComposer,
    $$JournalPostingsTableAnnotationComposer,
    $$JournalPostingsTableCreateCompanionBuilder,
    $$JournalPostingsTableUpdateCompanionBuilder,
    (JournalPosting, $$JournalPostingsTableReferences),
    JournalPosting,
    PrefetchHooks Function(
        {bool transactionId,
        bool accountId,
        bool categoryId,
        bool envelopeId})> {
  $$JournalPostingsTableTableManager(
      _$AppDatabase db, $JournalPostingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalPostingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalPostingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalPostingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> transactionId = const Value.absent(),
            Value<int> accountId = const Value.absent(),
            Value<int> debitVnd = const Value.absent(),
            Value<int> creditVnd = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int?> envelopeId = const Value.absent(),
          }) =>
              JournalPostingsCompanion(
            id: id,
            transactionId: transactionId,
            accountId: accountId,
            debitVnd: debitVnd,
            creditVnd: creditVnd,
            categoryId: categoryId,
            envelopeId: envelopeId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int transactionId,
            required int accountId,
            Value<int> debitVnd = const Value.absent(),
            Value<int> creditVnd = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int?> envelopeId = const Value.absent(),
          }) =>
              JournalPostingsCompanion.insert(
            id: id,
            transactionId: transactionId,
            accountId: accountId,
            debitVnd: debitVnd,
            creditVnd: creditVnd,
            categoryId: categoryId,
            envelopeId: envelopeId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$JournalPostingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {transactionId = false,
              accountId = false,
              categoryId = false,
              envelopeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (transactionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.transactionId,
                    referencedTable: $$JournalPostingsTableReferences
                        ._transactionIdTable(db),
                    referencedColumn: $$JournalPostingsTableReferences
                        ._transactionIdTable(db)
                        .id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$JournalPostingsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$JournalPostingsTableReferences._accountIdTable(db).id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$JournalPostingsTableReferences._categoryIdTable(db),
                    referencedColumn: $$JournalPostingsTableReferences
                        ._categoryIdTable(db)
                        .id,
                  ) as T;
                }
                if (envelopeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.envelopeId,
                    referencedTable:
                        $$JournalPostingsTableReferences._envelopeIdTable(db),
                    referencedColumn: $$JournalPostingsTableReferences
                        ._envelopeIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$JournalPostingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $JournalPostingsTable,
    JournalPosting,
    $$JournalPostingsTableFilterComposer,
    $$JournalPostingsTableOrderingComposer,
    $$JournalPostingsTableAnnotationComposer,
    $$JournalPostingsTableCreateCompanionBuilder,
    $$JournalPostingsTableUpdateCompanionBuilder,
    (JournalPosting, $$JournalPostingsTableReferences),
    JournalPosting,
    PrefetchHooks Function(
        {bool transactionId,
        bool accountId,
        bool categoryId,
        bool envelopeId})>;
typedef $$ScheduledItemsTableCreateCompanionBuilder = ScheduledItemsCompanion
    Function({
  Value<int> id,
  required String kind,
  required String title,
  required int amountVnd,
  required int dueDateMs,
  Value<String> recurrence,
  Value<int?> anchorDayOfMonth,
  Value<int?> categoryId,
  Value<int?> linkedEnvelopeId,
  Value<String> status,
  Value<int?> paidTransactionId,
  Value<int> reminderDaysBefore,
});
typedef $$ScheduledItemsTableUpdateCompanionBuilder = ScheduledItemsCompanion
    Function({
  Value<int> id,
  Value<String> kind,
  Value<String> title,
  Value<int> amountVnd,
  Value<int> dueDateMs,
  Value<String> recurrence,
  Value<int?> anchorDayOfMonth,
  Value<int?> categoryId,
  Value<int?> linkedEnvelopeId,
  Value<String> status,
  Value<int?> paidTransactionId,
  Value<int> reminderDaysBefore,
});

final class $$ScheduledItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ScheduledItemsTable, ScheduledItem> {
  $$ScheduledItemsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.scheduledItems.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    if ($_item.categoryId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.categoryId!));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EnvelopesTable _linkedEnvelopeIdTable(_$AppDatabase db) =>
      db.envelopes.createAlias($_aliasNameGenerator(
          db.scheduledItems.linkedEnvelopeId, db.envelopes.id));

  $$EnvelopesTableProcessedTableManager? get linkedEnvelopeId {
    if ($_item.linkedEnvelopeId == null) return null;
    final manager = $$EnvelopesTableTableManager($_db, $_db.envelopes)
        .filter((f) => f.id($_item.linkedEnvelopeId!));
    final item = $_typedResult.readTableOrNull(_linkedEnvelopeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $JournalTransactionsTable _paidTransactionIdTable(_$AppDatabase db) =>
      db.journalTransactions.createAlias($_aliasNameGenerator(
          db.scheduledItems.paidTransactionId, db.journalTransactions.id));

  $$JournalTransactionsTableProcessedTableManager? get paidTransactionId {
    if ($_item.paidTransactionId == null) return null;
    final manager =
        $$JournalTransactionsTableTableManager($_db, $_db.journalTransactions)
            .filter((f) => f.id($_item.paidTransactionId!));
    final item = $_typedResult.readTableOrNull(_paidTransactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$EnvelopeMovementsTable, List<EnvelopeMovement>>
      _envelopeMovementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.envelopeMovements,
              aliasName: $_aliasNameGenerator(db.scheduledItems.id,
                  db.envelopeMovements.linkedObligationId));

  $$EnvelopeMovementsTableProcessedTableManager get envelopeMovementsRefs {
    final manager =
        $$EnvelopeMovementsTableTableManager($_db, $_db.envelopeMovements)
            .filter((f) => f.linkedObligationId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_envelopeMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ScheduledItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduledItemsTable> {
  $$ScheduledItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountVnd => $composableBuilder(
      column: $table.amountVnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueDateMs => $composableBuilder(
      column: $table.dueDateMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrence => $composableBuilder(
      column: $table.recurrence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get anchorDayOfMonth => $composableBuilder(
      column: $table.anchorDayOfMonth,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderDaysBefore => $composableBuilder(
      column: $table.reminderDaysBefore,
      builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnvelopesTableFilterComposer get linkedEnvelopeId {
    final $$EnvelopesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.linkedEnvelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableFilterComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$JournalTransactionsTableFilterComposer get paidTransactionId {
    final $$JournalTransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paidTransactionId,
        referencedTable: $db.journalTransactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalTransactionsTableFilterComposer(
              $db: $db,
              $table: $db.journalTransactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> envelopeMovementsRefs(
      Expression<bool> Function($$EnvelopeMovementsTableFilterComposer f) f) {
    final $$EnvelopeMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.envelopeMovements,
        getReferencedColumn: (t) => t.linkedObligationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopeMovementsTableFilterComposer(
              $db: $db,
              $table: $db.envelopeMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ScheduledItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduledItemsTable> {
  $$ScheduledItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountVnd => $composableBuilder(
      column: $table.amountVnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueDateMs => $composableBuilder(
      column: $table.dueDateMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrence => $composableBuilder(
      column: $table.recurrence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get anchorDayOfMonth => $composableBuilder(
      column: $table.anchorDayOfMonth,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderDaysBefore => $composableBuilder(
      column: $table.reminderDaysBefore,
      builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnvelopesTableOrderingComposer get linkedEnvelopeId {
    final $$EnvelopesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.linkedEnvelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableOrderingComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$JournalTransactionsTableOrderingComposer get paidTransactionId {
    final $$JournalTransactionsTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.paidTransactionId,
            referencedTable: $db.journalTransactions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$JournalTransactionsTableOrderingComposer(
                  $db: $db,
                  $table: $db.journalTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$ScheduledItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduledItemsTable> {
  $$ScheduledItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get amountVnd =>
      $composableBuilder(column: $table.amountVnd, builder: (column) => column);

  GeneratedColumn<int> get dueDateMs =>
      $composableBuilder(column: $table.dueDateMs, builder: (column) => column);

  GeneratedColumn<String> get recurrence => $composableBuilder(
      column: $table.recurrence, builder: (column) => column);

  GeneratedColumn<int> get anchorDayOfMonth => $composableBuilder(
      column: $table.anchorDayOfMonth, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get reminderDaysBefore => $composableBuilder(
      column: $table.reminderDaysBefore, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnvelopesTableAnnotationComposer get linkedEnvelopeId {
    final $$EnvelopesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.linkedEnvelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableAnnotationComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$JournalTransactionsTableAnnotationComposer get paidTransactionId {
    final $$JournalTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.paidTransactionId,
            referencedTable: $db.journalTransactions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$JournalTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.journalTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  Expression<T> envelopeMovementsRefs<T extends Object>(
      Expression<T> Function($$EnvelopeMovementsTableAnnotationComposer a) f) {
    final $$EnvelopeMovementsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.envelopeMovements,
            getReferencedColumn: (t) => t.linkedObligationId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$EnvelopeMovementsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.envelopeMovements,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ScheduledItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScheduledItemsTable,
    ScheduledItem,
    $$ScheduledItemsTableFilterComposer,
    $$ScheduledItemsTableOrderingComposer,
    $$ScheduledItemsTableAnnotationComposer,
    $$ScheduledItemsTableCreateCompanionBuilder,
    $$ScheduledItemsTableUpdateCompanionBuilder,
    (ScheduledItem, $$ScheduledItemsTableReferences),
    ScheduledItem,
    PrefetchHooks Function(
        {bool categoryId,
        bool linkedEnvelopeId,
        bool paidTransactionId,
        bool envelopeMovementsRefs})> {
  $$ScheduledItemsTableTableManager(
      _$AppDatabase db, $ScheduledItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduledItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduledItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduledItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> amountVnd = const Value.absent(),
            Value<int> dueDateMs = const Value.absent(),
            Value<String> recurrence = const Value.absent(),
            Value<int?> anchorDayOfMonth = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int?> linkedEnvelopeId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> paidTransactionId = const Value.absent(),
            Value<int> reminderDaysBefore = const Value.absent(),
          }) =>
              ScheduledItemsCompanion(
            id: id,
            kind: kind,
            title: title,
            amountVnd: amountVnd,
            dueDateMs: dueDateMs,
            recurrence: recurrence,
            anchorDayOfMonth: anchorDayOfMonth,
            categoryId: categoryId,
            linkedEnvelopeId: linkedEnvelopeId,
            status: status,
            paidTransactionId: paidTransactionId,
            reminderDaysBefore: reminderDaysBefore,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String kind,
            required String title,
            required int amountVnd,
            required int dueDateMs,
            Value<String> recurrence = const Value.absent(),
            Value<int?> anchorDayOfMonth = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int?> linkedEnvelopeId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> paidTransactionId = const Value.absent(),
            Value<int> reminderDaysBefore = const Value.absent(),
          }) =>
              ScheduledItemsCompanion.insert(
            id: id,
            kind: kind,
            title: title,
            amountVnd: amountVnd,
            dueDateMs: dueDateMs,
            recurrence: recurrence,
            anchorDayOfMonth: anchorDayOfMonth,
            categoryId: categoryId,
            linkedEnvelopeId: linkedEnvelopeId,
            status: status,
            paidTransactionId: paidTransactionId,
            reminderDaysBefore: reminderDaysBefore,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ScheduledItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {categoryId = false,
              linkedEnvelopeId = false,
              paidTransactionId = false,
              envelopeMovementsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (envelopeMovementsRefs) db.envelopeMovements
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$ScheduledItemsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$ScheduledItemsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }
                if (linkedEnvelopeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.linkedEnvelopeId,
                    referencedTable: $$ScheduledItemsTableReferences
                        ._linkedEnvelopeIdTable(db),
                    referencedColumn: $$ScheduledItemsTableReferences
                        ._linkedEnvelopeIdTable(db)
                        .id,
                  ) as T;
                }
                if (paidTransactionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.paidTransactionId,
                    referencedTable: $$ScheduledItemsTableReferences
                        ._paidTransactionIdTable(db),
                    referencedColumn: $$ScheduledItemsTableReferences
                        ._paidTransactionIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (envelopeMovementsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ScheduledItemsTableReferences
                            ._envelopeMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ScheduledItemsTableReferences(db, table, p0)
                                .envelopeMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.linkedObligationId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ScheduledItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ScheduledItemsTable,
    ScheduledItem,
    $$ScheduledItemsTableFilterComposer,
    $$ScheduledItemsTableOrderingComposer,
    $$ScheduledItemsTableAnnotationComposer,
    $$ScheduledItemsTableCreateCompanionBuilder,
    $$ScheduledItemsTableUpdateCompanionBuilder,
    (ScheduledItem, $$ScheduledItemsTableReferences),
    ScheduledItem,
    PrefetchHooks Function(
        {bool categoryId,
        bool linkedEnvelopeId,
        bool paidTransactionId,
        bool envelopeMovementsRefs})>;
typedef $$EnvelopeMovementsTableCreateCompanionBuilder
    = EnvelopeMovementsCompanion Function({
  Value<int> id,
  required String movementType,
  required int amountVnd,
  Value<int?> sourceEnvelopeId,
  Value<int?> destEnvelopeId,
  Value<int?> linkedTransactionId,
  Value<int?> linkedObligationId,
  required int occurredAt,
});
typedef $$EnvelopeMovementsTableUpdateCompanionBuilder
    = EnvelopeMovementsCompanion Function({
  Value<int> id,
  Value<String> movementType,
  Value<int> amountVnd,
  Value<int?> sourceEnvelopeId,
  Value<int?> destEnvelopeId,
  Value<int?> linkedTransactionId,
  Value<int?> linkedObligationId,
  Value<int> occurredAt,
});

final class $$EnvelopeMovementsTableReferences extends BaseReferences<
    _$AppDatabase, $EnvelopeMovementsTable, EnvelopeMovement> {
  $$EnvelopeMovementsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $EnvelopesTable _sourceEnvelopeIdTable(_$AppDatabase db) =>
      db.envelopes.createAlias($_aliasNameGenerator(
          db.envelopeMovements.sourceEnvelopeId, db.envelopes.id));

  $$EnvelopesTableProcessedTableManager? get sourceEnvelopeId {
    if ($_item.sourceEnvelopeId == null) return null;
    final manager = $$EnvelopesTableTableManager($_db, $_db.envelopes)
        .filter((f) => f.id($_item.sourceEnvelopeId!));
    final item = $_typedResult.readTableOrNull(_sourceEnvelopeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EnvelopesTable _destEnvelopeIdTable(_$AppDatabase db) =>
      db.envelopes.createAlias($_aliasNameGenerator(
          db.envelopeMovements.destEnvelopeId, db.envelopes.id));

  $$EnvelopesTableProcessedTableManager? get destEnvelopeId {
    if ($_item.destEnvelopeId == null) return null;
    final manager = $$EnvelopesTableTableManager($_db, $_db.envelopes)
        .filter((f) => f.id($_item.destEnvelopeId!));
    final item = $_typedResult.readTableOrNull(_destEnvelopeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $JournalTransactionsTable _linkedTransactionIdTable(
          _$AppDatabase db) =>
      db.journalTransactions.createAlias($_aliasNameGenerator(
          db.envelopeMovements.linkedTransactionId, db.journalTransactions.id));

  $$JournalTransactionsTableProcessedTableManager? get linkedTransactionId {
    if ($_item.linkedTransactionId == null) return null;
    final manager =
        $$JournalTransactionsTableTableManager($_db, $_db.journalTransactions)
            .filter((f) => f.id($_item.linkedTransactionId!));
    final item = $_typedResult.readTableOrNull(_linkedTransactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ScheduledItemsTable _linkedObligationIdTable(_$AppDatabase db) =>
      db.scheduledItems.createAlias($_aliasNameGenerator(
          db.envelopeMovements.linkedObligationId, db.scheduledItems.id));

  $$ScheduledItemsTableProcessedTableManager? get linkedObligationId {
    if ($_item.linkedObligationId == null) return null;
    final manager = $$ScheduledItemsTableTableManager($_db, $_db.scheduledItems)
        .filter((f) => f.id($_item.linkedObligationId!));
    final item = $_typedResult.readTableOrNull(_linkedObligationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EnvelopeMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $EnvelopeMovementsTable> {
  $$EnvelopeMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get movementType => $composableBuilder(
      column: $table.movementType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountVnd => $composableBuilder(
      column: $table.amountVnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  $$EnvelopesTableFilterComposer get sourceEnvelopeId {
    final $$EnvelopesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceEnvelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableFilterComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnvelopesTableFilterComposer get destEnvelopeId {
    final $$EnvelopesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destEnvelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableFilterComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$JournalTransactionsTableFilterComposer get linkedTransactionId {
    final $$JournalTransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.linkedTransactionId,
        referencedTable: $db.journalTransactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$JournalTransactionsTableFilterComposer(
              $db: $db,
              $table: $db.journalTransactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ScheduledItemsTableFilterComposer get linkedObligationId {
    final $$ScheduledItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.linkedObligationId,
        referencedTable: $db.scheduledItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScheduledItemsTableFilterComposer(
              $db: $db,
              $table: $db.scheduledItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EnvelopeMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $EnvelopeMovementsTable> {
  $$EnvelopeMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get movementType => $composableBuilder(
      column: $table.movementType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountVnd => $composableBuilder(
      column: $table.amountVnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  $$EnvelopesTableOrderingComposer get sourceEnvelopeId {
    final $$EnvelopesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceEnvelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableOrderingComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnvelopesTableOrderingComposer get destEnvelopeId {
    final $$EnvelopesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destEnvelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableOrderingComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$JournalTransactionsTableOrderingComposer get linkedTransactionId {
    final $$JournalTransactionsTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.linkedTransactionId,
            referencedTable: $db.journalTransactions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$JournalTransactionsTableOrderingComposer(
                  $db: $db,
                  $table: $db.journalTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$ScheduledItemsTableOrderingComposer get linkedObligationId {
    final $$ScheduledItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.linkedObligationId,
        referencedTable: $db.scheduledItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScheduledItemsTableOrderingComposer(
              $db: $db,
              $table: $db.scheduledItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EnvelopeMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnvelopeMovementsTable> {
  $$EnvelopeMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get movementType => $composableBuilder(
      column: $table.movementType, builder: (column) => column);

  GeneratedColumn<int> get amountVnd =>
      $composableBuilder(column: $table.amountVnd, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  $$EnvelopesTableAnnotationComposer get sourceEnvelopeId {
    final $$EnvelopesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceEnvelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableAnnotationComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EnvelopesTableAnnotationComposer get destEnvelopeId {
    final $$EnvelopesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.destEnvelopeId,
        referencedTable: $db.envelopes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EnvelopesTableAnnotationComposer(
              $db: $db,
              $table: $db.envelopes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$JournalTransactionsTableAnnotationComposer get linkedTransactionId {
    final $$JournalTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.linkedTransactionId,
            referencedTable: $db.journalTransactions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$JournalTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.journalTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$ScheduledItemsTableAnnotationComposer get linkedObligationId {
    final $$ScheduledItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.linkedObligationId,
        referencedTable: $db.scheduledItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScheduledItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.scheduledItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EnvelopeMovementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EnvelopeMovementsTable,
    EnvelopeMovement,
    $$EnvelopeMovementsTableFilterComposer,
    $$EnvelopeMovementsTableOrderingComposer,
    $$EnvelopeMovementsTableAnnotationComposer,
    $$EnvelopeMovementsTableCreateCompanionBuilder,
    $$EnvelopeMovementsTableUpdateCompanionBuilder,
    (EnvelopeMovement, $$EnvelopeMovementsTableReferences),
    EnvelopeMovement,
    PrefetchHooks Function(
        {bool sourceEnvelopeId,
        bool destEnvelopeId,
        bool linkedTransactionId,
        bool linkedObligationId})> {
  $$EnvelopeMovementsTableTableManager(
      _$AppDatabase db, $EnvelopeMovementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvelopeMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnvelopeMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnvelopeMovementsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> movementType = const Value.absent(),
            Value<int> amountVnd = const Value.absent(),
            Value<int?> sourceEnvelopeId = const Value.absent(),
            Value<int?> destEnvelopeId = const Value.absent(),
            Value<int?> linkedTransactionId = const Value.absent(),
            Value<int?> linkedObligationId = const Value.absent(),
            Value<int> occurredAt = const Value.absent(),
          }) =>
              EnvelopeMovementsCompanion(
            id: id,
            movementType: movementType,
            amountVnd: amountVnd,
            sourceEnvelopeId: sourceEnvelopeId,
            destEnvelopeId: destEnvelopeId,
            linkedTransactionId: linkedTransactionId,
            linkedObligationId: linkedObligationId,
            occurredAt: occurredAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String movementType,
            required int amountVnd,
            Value<int?> sourceEnvelopeId = const Value.absent(),
            Value<int?> destEnvelopeId = const Value.absent(),
            Value<int?> linkedTransactionId = const Value.absent(),
            Value<int?> linkedObligationId = const Value.absent(),
            required int occurredAt,
          }) =>
              EnvelopeMovementsCompanion.insert(
            id: id,
            movementType: movementType,
            amountVnd: amountVnd,
            sourceEnvelopeId: sourceEnvelopeId,
            destEnvelopeId: destEnvelopeId,
            linkedTransactionId: linkedTransactionId,
            linkedObligationId: linkedObligationId,
            occurredAt: occurredAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EnvelopeMovementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {sourceEnvelopeId = false,
              destEnvelopeId = false,
              linkedTransactionId = false,
              linkedObligationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sourceEnvelopeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourceEnvelopeId,
                    referencedTable: $$EnvelopeMovementsTableReferences
                        ._sourceEnvelopeIdTable(db),
                    referencedColumn: $$EnvelopeMovementsTableReferences
                        ._sourceEnvelopeIdTable(db)
                        .id,
                  ) as T;
                }
                if (destEnvelopeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.destEnvelopeId,
                    referencedTable: $$EnvelopeMovementsTableReferences
                        ._destEnvelopeIdTable(db),
                    referencedColumn: $$EnvelopeMovementsTableReferences
                        ._destEnvelopeIdTable(db)
                        .id,
                  ) as T;
                }
                if (linkedTransactionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.linkedTransactionId,
                    referencedTable: $$EnvelopeMovementsTableReferences
                        ._linkedTransactionIdTable(db),
                    referencedColumn: $$EnvelopeMovementsTableReferences
                        ._linkedTransactionIdTable(db)
                        .id,
                  ) as T;
                }
                if (linkedObligationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.linkedObligationId,
                    referencedTable: $$EnvelopeMovementsTableReferences
                        ._linkedObligationIdTable(db),
                    referencedColumn: $$EnvelopeMovementsTableReferences
                        ._linkedObligationIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EnvelopeMovementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EnvelopeMovementsTable,
    EnvelopeMovement,
    $$EnvelopeMovementsTableFilterComposer,
    $$EnvelopeMovementsTableOrderingComposer,
    $$EnvelopeMovementsTableAnnotationComposer,
    $$EnvelopeMovementsTableCreateCompanionBuilder,
    $$EnvelopeMovementsTableUpdateCompanionBuilder,
    (EnvelopeMovement, $$EnvelopeMovementsTableReferences),
    EnvelopeMovement,
    PrefetchHooks Function(
        {bool sourceEnvelopeId,
        bool destEnvelopeId,
        bool linkedTransactionId,
        bool linkedObligationId})>;
typedef $$CategoryBudgetsTableCreateCompanionBuilder = CategoryBudgetsCompanion
    Function({
  Value<int> id,
  required int categoryId,
  required int yearMonth,
  required int limitVnd,
  Value<int> alertThresholdPct,
});
typedef $$CategoryBudgetsTableUpdateCompanionBuilder = CategoryBudgetsCompanion
    Function({
  Value<int> id,
  Value<int> categoryId,
  Value<int> yearMonth,
  Value<int> limitVnd,
  Value<int> alertThresholdPct,
});

final class $$CategoryBudgetsTableReferences extends BaseReferences<
    _$AppDatabase, $CategoryBudgetsTable, CategoryBudget> {
  $$CategoryBudgetsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias($_aliasNameGenerator(
          db.categoryBudgets.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager get categoryId {
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.categoryId));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CategoryBudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get yearMonth => $composableBuilder(
      column: $table.yearMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get limitVnd => $composableBuilder(
      column: $table.limitVnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get alertThresholdPct => $composableBuilder(
      column: $table.alertThresholdPct,
      builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CategoryBudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get yearMonth => $composableBuilder(
      column: $table.yearMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get limitVnd => $composableBuilder(
      column: $table.limitVnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get alertThresholdPct => $composableBuilder(
      column: $table.alertThresholdPct,
      builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CategoryBudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get yearMonth =>
      $composableBuilder(column: $table.yearMonth, builder: (column) => column);

  GeneratedColumn<int> get limitVnd =>
      $composableBuilder(column: $table.limitVnd, builder: (column) => column);

  GeneratedColumn<int> get alertThresholdPct => $composableBuilder(
      column: $table.alertThresholdPct, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CategoryBudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoryBudgetsTable,
    CategoryBudget,
    $$CategoryBudgetsTableFilterComposer,
    $$CategoryBudgetsTableOrderingComposer,
    $$CategoryBudgetsTableAnnotationComposer,
    $$CategoryBudgetsTableCreateCompanionBuilder,
    $$CategoryBudgetsTableUpdateCompanionBuilder,
    (CategoryBudget, $$CategoryBudgetsTableReferences),
    CategoryBudget,
    PrefetchHooks Function({bool categoryId})> {
  $$CategoryBudgetsTableTableManager(
      _$AppDatabase db, $CategoryBudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<int> yearMonth = const Value.absent(),
            Value<int> limitVnd = const Value.absent(),
            Value<int> alertThresholdPct = const Value.absent(),
          }) =>
              CategoryBudgetsCompanion(
            id: id,
            categoryId: categoryId,
            yearMonth: yearMonth,
            limitVnd: limitVnd,
            alertThresholdPct: alertThresholdPct,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int categoryId,
            required int yearMonth,
            required int limitVnd,
            Value<int> alertThresholdPct = const Value.absent(),
          }) =>
              CategoryBudgetsCompanion.insert(
            id: id,
            categoryId: categoryId,
            yearMonth: yearMonth,
            limitVnd: limitVnd,
            alertThresholdPct: alertThresholdPct,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoryBudgetsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$CategoryBudgetsTableReferences._categoryIdTable(db),
                    referencedColumn: $$CategoryBudgetsTableReferences
                        ._categoryIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CategoryBudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoryBudgetsTable,
    CategoryBudget,
    $$CategoryBudgetsTableFilterComposer,
    $$CategoryBudgetsTableOrderingComposer,
    $$CategoryBudgetsTableAnnotationComposer,
    $$CategoryBudgetsTableCreateCompanionBuilder,
    $$CategoryBudgetsTableUpdateCompanionBuilder,
    (CategoryBudget, $$CategoryBudgetsTableReferences),
    CategoryBudget,
    PrefetchHooks Function({bool categoryId})>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<int> minimumCashBufferVnd,
  Value<int> periodStartDay,
  Value<int> dailyReminderHour,
  Value<int> dailyReminderMinute,
  Value<bool> notificationsEnabled,
  Value<int> schemaVersion,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<int> minimumCashBufferVnd,
  Value<int> periodStartDay,
  Value<int> dailyReminderHour,
  Value<int> dailyReminderMinute,
  Value<bool> notificationsEnabled,
  Value<int> schemaVersion,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minimumCashBufferVnd => $composableBuilder(
      column: $table.minimumCashBufferVnd,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get periodStartDay => $composableBuilder(
      column: $table.periodStartDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyReminderHour => $composableBuilder(
      column: $table.dailyReminderHour,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyReminderMinute => $composableBuilder(
      column: $table.dailyReminderMinute,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minimumCashBufferVnd => $composableBuilder(
      column: $table.minimumCashBufferVnd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get periodStartDay => $composableBuilder(
      column: $table.periodStartDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyReminderHour => $composableBuilder(
      column: $table.dailyReminderHour,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyReminderMinute => $composableBuilder(
      column: $table.dailyReminderMinute,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get minimumCashBufferVnd => $composableBuilder(
      column: $table.minimumCashBufferVnd, builder: (column) => column);

  GeneratedColumn<int> get periodStartDay => $composableBuilder(
      column: $table.periodStartDay, builder: (column) => column);

  GeneratedColumn<int> get dailyReminderHour => $composableBuilder(
      column: $table.dailyReminderHour, builder: (column) => column);

  GeneratedColumn<int> get dailyReminderMinute => $composableBuilder(
      column: $table.dailyReminderMinute, builder: (column) => column);

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> minimumCashBufferVnd = const Value.absent(),
            Value<int> periodStartDay = const Value.absent(),
            Value<int> dailyReminderHour = const Value.absent(),
            Value<int> dailyReminderMinute = const Value.absent(),
            Value<bool> notificationsEnabled = const Value.absent(),
            Value<int> schemaVersion = const Value.absent(),
          }) =>
              SettingsCompanion(
            id: id,
            minimumCashBufferVnd: minimumCashBufferVnd,
            periodStartDay: periodStartDay,
            dailyReminderHour: dailyReminderHour,
            dailyReminderMinute: dailyReminderMinute,
            notificationsEnabled: notificationsEnabled,
            schemaVersion: schemaVersion,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> minimumCashBufferVnd = const Value.absent(),
            Value<int> periodStartDay = const Value.absent(),
            Value<int> dailyReminderHour = const Value.absent(),
            Value<int> dailyReminderMinute = const Value.absent(),
            Value<bool> notificationsEnabled = const Value.absent(),
            Value<int> schemaVersion = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            id: id,
            minimumCashBufferVnd: minimumCashBufferVnd,
            periodStartDay: periodStartDay,
            dailyReminderHour: dailyReminderHour,
            dailyReminderMinute: dailyReminderMinute,
            notificationsEnabled: notificationsEnabled,
            schemaVersion: schemaVersion,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LedgerAccountsTableTableManager get ledgerAccounts =>
      $$LedgerAccountsTableTableManager(_db, _db.ledgerAccounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$JournalTransactionsTableTableManager get journalTransactions =>
      $$JournalTransactionsTableTableManager(_db, _db.journalTransactions);
  $$EnvelopesTableTableManager get envelopes =>
      $$EnvelopesTableTableManager(_db, _db.envelopes);
  $$JournalPostingsTableTableManager get journalPostings =>
      $$JournalPostingsTableTableManager(_db, _db.journalPostings);
  $$ScheduledItemsTableTableManager get scheduledItems =>
      $$ScheduledItemsTableTableManager(_db, _db.scheduledItems);
  $$EnvelopeMovementsTableTableManager get envelopeMovements =>
      $$EnvelopeMovementsTableTableManager(_db, _db.envelopeMovements);
  $$CategoryBudgetsTableTableManager get categoryBudgets =>
      $$CategoryBudgetsTableTableManager(_db, _db.categoryBudgets);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
