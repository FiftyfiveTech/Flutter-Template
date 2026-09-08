import 'host_document_selection.dart';
import 'host_document_type.dart';

/// Basics collected on H-03 · Documents: payout details for every host,
/// the food/alcohol declarations that decide whether a venue host also
/// needs FSSAI/excise licence fields, and the picked document files.
class HostDocumentsDraft {
  const HostDocumentsDraft({
    this.upiId = '',
    this.servesFood = false,
    this.servesAlcohol = false,
    this.licenceValidFrom,
    this.licenceValidTo,
    this.documents = const {},
  });

  final String upiId;
  final bool servesFood;
  final bool servesAlcohol;
  final DateTime? licenceValidFrom;
  final DateTime? licenceValidTo;
  final Map<HostDocumentType, HostDocumentSelection> documents;

  HostDocumentsDraft copyWith({
    String? upiId,
    bool? servesFood,
    bool? servesAlcohol,
    DateTime? licenceValidFrom,
    DateTime? licenceValidTo,
    Map<HostDocumentType, HostDocumentSelection>? documents,
  }) {
    return HostDocumentsDraft(
      upiId: upiId ?? this.upiId,
      servesFood: servesFood ?? this.servesFood,
      servesAlcohol: servesAlcohol ?? this.servesAlcohol,
      licenceValidFrom: licenceValidFrom ?? this.licenceValidFrom,
      licenceValidTo: licenceValidTo ?? this.licenceValidTo,
      documents: documents ?? this.documents,
    );
  }
}
