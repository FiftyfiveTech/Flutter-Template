import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/host_document_selection.dart';
import '../../domain/entities/host_document_type.dart';
import '../../domain/entities/host_documents_draft.dart';
import '../../domain/entities/host_onboarding_progress.dart';
import '../../domain/entities/host_onboarding_step.dart';
import '../../domain/entities/host_type.dart';

abstract interface class HostOnboardingProgressLocalDatasource {
  Future<HostOnboardingProgress?> load();
  Future<void> save(HostOnboardingProgress progress);
  Future<void> clear();
}

class DriftHostOnboardingProgressLocalDatasource
    implements HostOnboardingProgressLocalDatasource {
  DriftHostOnboardingProgressLocalDatasource(this._db);
  final AppDatabase _db;

  @override
  Future<HostOnboardingProgress?> load() async {
    final row = await (_db.select(
      _db.hostOnboardingProgressTable,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row);
  }

  @override
  Future<void> save(HostOnboardingProgress progress) {
    return _db
        .into(_db.hostOnboardingProgressTable)
        .insertOnConflictUpdate(_toCompanion(progress));
  }

  @override
  Future<void> clear() {
    return (_db.delete(
      _db.hostOnboardingProgressTable,
    )..where((t) => t.id.equals(0))).go();
  }

  HostOnboardingProgress _toEntity(HostOnboardingProgressTableData row) {
    final documentTypesByName = HostDocumentType.values.asNameMap();
    final decoded = jsonDecode(row.documentsJson) as Map<String, dynamic>;
    final documents = <HostDocumentType, HostDocumentSelection>{};
    for (final entry in decoded.entries) {
      final type = documentTypesByName[entry.key];
      if (type == null) continue;
      final value = entry.value as Map<String, dynamic>;
      documents[type] = HostDocumentSelection(
        fileName: value['fileName'] as String,
        sizeBytes: value['sizeBytes'] as int?,
        documentId: value['documentId'] as String?,
      );
    }

    return HostOnboardingProgress(
      step: HostOnboardingStep.values.byName(row.step),
      hostType: row.hostType == null
          ? null
          : HostType.values.byName(row.hostType!),
      documentsDraft: HostDocumentsDraft(
        upiId: row.upiId,
        servesFood: row.servesFood,
        servesAlcohol: row.servesAlcohol,
        fssaiLicenceValidFrom: row.fssaiValidFrom,
        fssaiLicenceValidTo: row.fssaiValidTo,
        exciseLicenceValidFrom: row.exciseValidFrom,
        exciseLicenceValidTo: row.exciseValidTo,
        documents: documents,
      ),
    );
  }

  HostOnboardingProgressTableCompanion _toCompanion(
    HostOnboardingProgress progress,
  ) {
    final draft = progress.documentsDraft;
    final documentsJson = jsonEncode({
      for (final entry in draft.documents.entries)
        entry.key.name: {
          'fileName': entry.value.fileName,
          'sizeBytes': entry.value.sizeBytes,
          'documentId': entry.value.documentId,
        },
    });

    return HostOnboardingProgressTableCompanion.insert(
      id: const Value(0),
      step: progress.step.name,
      hostType: Value(progress.hostType?.name),
      upiId: Value(draft.upiId),
      servesFood: Value(draft.servesFood),
      servesAlcohol: Value(draft.servesAlcohol),
      fssaiValidFrom: Value(draft.fssaiLicenceValidFrom),
      fssaiValidTo: Value(draft.fssaiLicenceValidTo),
      exciseValidFrom: Value(draft.exciseLicenceValidFrom),
      exciseValidTo: Value(draft.exciseLicenceValidTo),
      documentsJson: Value(documentsJson),
    );
  }
}
