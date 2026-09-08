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
}
