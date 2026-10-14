import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/host_document_status.dart';
import 'host_document_status_api_providers.dart';

/// Whether every submitted document is approved, per
/// `GET /api/v1/host/documents` — the same rule H-04 · Verification uses,
/// so Home and You can't disagree with it. `null` when the status
/// couldn't be fetched (offline/error); callers keep their last-known
/// value rather than downgrading a verified host to "pending".
Future<bool?> fetchHostIsVerified(Ref ref) async {
  final result = await ref.read(getHostDocumentsStatusUseCaseProvider)();
  return result.when(ok: (docs) => docs.allVerified, err: (_) => null);
}
