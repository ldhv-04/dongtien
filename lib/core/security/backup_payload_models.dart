import 'package:cryptography/cryptography.dart';

/// Thrown when the backup file exceeds the 25 MB maximum size limit.
class BackupSizeExceededException implements Exception {
  final int actualBytes;
  final int maxBytes;

  const BackupSizeExceededException({
    required this.actualBytes,
    required this.maxBytes,
  });

  @override
  String toString() =>
      'BackupSizeExceededException: File size ($actualBytes bytes) exceeds limit ($maxBytes bytes)';
}

/// Thrown when the outer JSON backup wrapper has invalid headers, magic string, or KDF parameters.
class InvalidBackupFormatException implements Exception {
  final String message;
  const InvalidBackupFormatException(this.message);

  @override
  String toString() => 'InvalidBackupFormatException: $message';
}

/// Thrown when decryption fails due to wrong password, modified ciphertext, or invalid MAC tag.
/// Extends [SecretBoxAuthenticationError] so callers catching either type work seamlessly.
class InvalidCredentialsException extends SecretBoxAuthenticationError {
  final String detail;

  InvalidCredentialsException([
    this.detail = 'Wrong password or tampered backup ciphertext/MAC',
  ]);

  @override
  String get message => detail;

  @override
  String toString() => 'InvalidCredentialsException: $detail';
}

/// Thrown when the decrypted inner JSON payload violates structural or double-entry invariants.
class BackupCorruptException implements Exception {
  final String message;
  const BackupCorruptException(this.message);

  @override
  String toString() => 'BackupCorruptException: $message';
}

/// Outer JSON envelope DTO (`DONGTIEN_ENC_V1`).
class EncryptedBackupEnvelope {
  static const String expectedMagic = 'DONGTIEN_ENC_V1';
  static const String expectedKdf = 'PBKDF2-HMAC-SHA256';
  static const String expectedCipher = 'AES-256-GCM';
  static const int defaultIterations = 120000;
  static const int minAllowedIterations = 100000;
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB

  final String magic;
  final int formatVersion;
  final int schemaVersion;
  final String createdAtIso;
  final String kdf;
  final int kdfIterations;
  final String saltB64;
  final String cipher;
  final String nonceB64;
  final String ciphertextB64;
  final String macB64;

  const EncryptedBackupEnvelope({
    required this.magic,
    required this.formatVersion,
    required this.schemaVersion,
    required this.createdAtIso,
    required this.kdf,
    required this.kdfIterations,
    required this.saltB64,
    required this.cipher,
    required this.nonceB64,
    required this.ciphertextB64,
    required this.macB64,
  });

  Map<String, dynamic> toJson() => {
        'magic': magic,
        'formatVersion': formatVersion,
        'schemaVersion': schemaVersion,
        'createdAtIso': createdAtIso,
        'kdf': kdf,
        'kdfIterations': kdfIterations,
        'saltB64': saltB64,
        'cipher': cipher,
        'nonceB64': nonceB64,
        'ciphertextB64': ciphertextB64,
        'macB64': macB64,
      };

  factory EncryptedBackupEnvelope.fromJson(Map<String, dynamic> json) {
    final magic = json['magic'] as String?;
    if (magic != expectedMagic) {
      throw InvalidBackupFormatException(
        'Invalid magic header: "$magic" (expected "$expectedMagic")',
      );
    }
    final kdf = json['kdf'] as String?;
    if (kdf != expectedKdf) {
      throw InvalidBackupFormatException(
        'Unsupported KDF: "$kdf" (expected "$expectedKdf")',
      );
    }
    final cipher = json['cipher'] as String?;
    if (cipher != expectedCipher) {
      throw InvalidBackupFormatException(
        'Unsupported cipher: "$cipher" (expected "$expectedCipher")',
      );
    }
    final iterations = json['kdfIterations'] as int?;
    if (iterations == null || iterations < minAllowedIterations) {
      throw InvalidBackupFormatException(
        'Invalid kdfIterations: $iterations (min $minAllowedIterations)',
      );
    }

    final saltB64 = json['saltB64'] as String?;
    final nonceB64 = json['nonceB64'] as String?;
    final ciphertextB64 = json['ciphertextB64'] as String?;
    final macB64 = json['macB64'] as String?;
    final createdAtIso = json['createdAtIso'] as String? ?? '';
    final formatVersion = json['formatVersion'] as int? ?? 1;
    final schemaVersion = json['schemaVersion'] as int? ?? 1;

    if (saltB64 == null ||
        nonceB64 == null ||
        ciphertextB64 == null ||
        macB64 == null) {
      throw const InvalidBackupFormatException(
        'Missing required cryptographic fields in backup envelope',
      );
    }

    return EncryptedBackupEnvelope(
      magic: magic!,
      formatVersion: formatVersion,
      schemaVersion: schemaVersion,
      createdAtIso: createdAtIso,
      kdf: kdf!,
      kdfIterations: iterations,
      saltB64: saltB64,
      cipher: cipher!,
      nonceB64: nonceB64,
      ciphertextB64: ciphertextB64,
      macB64: macB64,
    );
  }
}

/// Summary of validated backup metadata for user confirmation dialog before atomic restore.
class BackupValidationResult {
  final String createdAtIso;
  final int schemaVersion;
  final int accountsCount;
  final int categoriesCount;
  final int transactionsCount;
  final int postingsCount;
  final int envelopesCount;
  final int movementsCount;
  final int budgetsCount;
  final int scheduledItemsCount;
  final Map<String, dynamic> rawPayload;

  const BackupValidationResult({
    required this.createdAtIso,
    required this.schemaVersion,
    required this.accountsCount,
    required this.categoriesCount,
    required this.transactionsCount,
    required this.postingsCount,
    required this.envelopesCount,
    required this.movementsCount,
    required this.budgetsCount,
    required this.scheduledItemsCount,
    required this.rawPayload,
  });
}
