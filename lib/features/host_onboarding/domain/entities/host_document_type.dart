/// A document H-03 may ask for. `businessRegistration` and `panCard` are
/// required for every host; the rest are venue-only (see
/// `host-app/01-host-onboarding.md` §3-4).
enum HostDocumentType {
  businessRegistration,
  panCard,
  addressProof,
  fssaiRegistration,
  exciseLicence,
}

extension HostDocumentTypeLabel on HostDocumentType {
  String get label => switch (this) {
    HostDocumentType.businessRegistration =>
      'Business registration or organiser ID',
    HostDocumentType.panCard => 'PAN card',
    HostDocumentType.addressProof => 'Premises address proof',
    HostDocumentType.fssaiRegistration => 'FSSAI registration',
    HostDocumentType.exciseLicence => 'Excise licence',
  };

  /// `fileType` query param sent to `POST /api/v1/uploads`, matching the
  /// enum the backend advertises (`profile_photo`, `business_registration`,
  /// `pan_document`, `excise_license`, `fssai_document`, `address_proof`,
  /// `event_cover_media`).
  String get apiValue => switch (this) {
    HostDocumentType.businessRegistration => 'business_registration',
    HostDocumentType.panCard => 'pan_document',
    HostDocumentType.addressProof => 'address_proof',
    HostDocumentType.fssaiRegistration => 'fssai_document',
    HostDocumentType.exciseLicence => 'excise_license',
  };

  /// `docType` sent to `POST /api/v1/host/submit-verification` — a
  /// different vocabulary from [apiValue]'s upload `fileType`.
  String get submitDocType => switch (this) {
    HostDocumentType.businessRegistration => 'business_registration',
    HostDocumentType.panCard => 'pan',
    HostDocumentType.addressProof => 'premises_address_proof',
    HostDocumentType.fssaiRegistration => 'fssai',
    HostDocumentType.exciseLicence => 'state_excise',
  };

  /// Reverses [submitDocType] — used to parse
  /// `GET /api/v1/host/documents`'s `docType` back into the enum. `null`
  /// for a value the client doesn't recognize, so an unexpected addition
  /// on the backend doesn't crash the status screen.
  static HostDocumentType? fromSubmitDocType(String value) {
    for (final type in HostDocumentType.values) {
      if (type.submitDocType == value) return type;
    }
    return null;
  }
}
