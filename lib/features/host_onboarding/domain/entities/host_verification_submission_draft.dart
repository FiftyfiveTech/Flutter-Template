import 'host_payout_details.dart';
import 'host_type.dart';
import 'host_verification_document.dart';

/// Everything `POST /api/v1/host/submit-verification` needs, assembled
/// from the H-02 (host type) and H-03 (documents/payout) steps once all
/// required documents have finished uploading.
class HostVerificationSubmissionDraft {
  const HostVerificationSubmissionDraft({
    required this.hostType,
    required this.servesFood,
    required this.servesAlcohol,
    required this.payoutDetails,
    required this.documents,
  });

  final HostType hostType;
  final bool servesFood;
  final bool servesAlcohol;
  final HostPayoutDetails payoutDetails;
  final List<HostVerificationDocument> documents;
}
