import 'host_document_selection.dart';
import 'host_document_type.dart';

/// Basics collected on H-03 · Documents: payout details for every host,
/// the food/alcohol declarations that decide whether a venue host also
/// needs FSSAI/excise licence fields (each with its own validity window,
/// `host-app/01-host-onboarding.md` §3–4), and the picked document files.
class HostDocumentsDraft {
  const HostDocumentsDraft({
    this.upiId = '',
    this.servesFood = false,
    this.servesAlcohol = false,
    this.fssaiLicenceValidFrom,
    this.fssaiLicenceValidTo,
    this.exciseLicenceValidFrom,
    this.exciseLicenceValidTo,
    this.documents = const {},
  });

  final String upiId;
  final bool servesFood;
  final bool servesAlcohol;
  final DateTime? fssaiLicenceValidFrom;
  final DateTime? fssaiLicenceValidTo;
  final DateTime? exciseLicenceValidFrom;
  final DateTime? exciseLicenceValidTo;
  final Map<HostDocumentType, HostDocumentSelection> documents;

  HostDocumentsDraft copyWith({
    String? upiId,
    bool? servesFood,
    bool? servesAlcohol,
    DateTime? fssaiLicenceValidFrom,
    DateTime? fssaiLicenceValidTo,
    DateTime? exciseLicenceValidFrom,
    DateTime? exciseLicenceValidTo,
    Map<HostDocumentType, HostDocumentSelection>? documents,
  }) {
    return HostDocumentsDraft(
      upiId: upiId ?? this.upiId,
      servesFood: servesFood ?? this.servesFood,
      servesAlcohol: servesAlcohol ?? this.servesAlcohol,
      fssaiLicenceValidFrom:
          fssaiLicenceValidFrom ?? this.fssaiLicenceValidFrom,
      fssaiLicenceValidTo: fssaiLicenceValidTo ?? this.fssaiLicenceValidTo,
      exciseLicenceValidFrom:
          exciseLicenceValidFrom ?? this.exciseLicenceValidFrom,
      exciseLicenceValidTo: exciseLicenceValidTo ?? this.exciseLicenceValidTo,
      documents: documents ?? this.documents,
    );
  }
}
