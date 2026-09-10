import '../../domain/entities/host_document_type.dart';
import '../../domain/entities/host_payout_details.dart';
import '../../domain/entities/host_type.dart';
import '../../domain/entities/host_verification_document.dart';
import '../../domain/entities/host_verification_result.dart';
import '../../domain/entities/host_verification_submission_draft.dart';

/// Request body for `POST /api/v1/host/submit-verification`.
class HostVerificationSubmissionRequestDto {
  const HostVerificationSubmissionRequestDto({
    required this.hostType,
    required this.servesFood,
    required this.servesAlcohol,
    required this.payoutDetails,
    required this.documents,
  });

  final String hostType;
  final bool servesFood;
  final bool servesAlcohol;
  final HostPayoutDetails payoutDetails;
  final List<HostVerificationDocumentDto> documents;

  factory HostVerificationSubmissionRequestDto.fromDraft(
    HostVerificationSubmissionDraft draft,
  ) {
    return HostVerificationSubmissionRequestDto(
      hostType: draft.hostType.apiValue,
      servesFood: draft.servesFood,
      servesAlcohol: draft.servesAlcohol,
      payoutDetails: draft.payoutDetails,
      documents: draft.documents
          .map(HostVerificationDocumentDto.fromEntity)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'hostType': hostType,
    'servesFood': servesFood,
    'servesAlcohol': servesAlcohol,
    'payoutDetails': _payoutDetailsJson(payoutDetails),
    'documents': documents.map((d) => d.toJson()).toList(),
  };

  static Map<String, dynamic> _payoutDetailsJson(HostPayoutDetails details) {
    return switch (details.method) {
      HostPayoutMethod.upi => {
        'method': details.method.apiValue,
        'vpa': details.vpa,
      },
      HostPayoutMethod.bank => {'method': details.method.apiValue},
    };
  }
}

/// One entry of the request's `documents` array.
class HostVerificationDocumentDto {
  const HostVerificationDocumentDto({
    required this.docType,
    required this.uploadId,
    this.issuedAt,
    this.expiresAt,
  });

  final String docType;
  final String uploadId;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  factory HostVerificationDocumentDto.fromEntity(
    HostVerificationDocument document,
  ) {
    return HostVerificationDocumentDto(
      docType: document.docType.submitDocType,
      uploadId: document.uploadId,
      issuedAt: document.issuedAt,
      expiresAt: document.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'docType': docType,
    'uploadId': uploadId,
    if (issuedAt != null) 'issuedAt': _dateOnly(issuedAt!),
    if (expiresAt != null) 'expiresAt': _dateOnly(expiresAt!),
  };

  static String _dateOnly(DateTime date) =>
      date.toIso8601String().split('T').first;
}

/// A successful submit-verification response. The API returns `data:
/// null` on success — there's no `accountStatus` here, just a
/// confirmation `message`; the real per-document status is read
/// separately from `GET /api/v1/host/documents` (H-04's status poll).
class HostVerificationSubmissionResponseDto {
  const HostVerificationSubmissionResponseDto({required this.message});

  final String message;

  factory HostVerificationSubmissionResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return HostVerificationSubmissionResponseDto(
      message: json['message'] as String? ?? 'Verification submitted',
    );
  }

  HostVerificationResult toEntity() => HostVerificationResult(message: message);
}
