/// Basics collected on H-01 · Signup, the first step of the host onboarding
/// wizard. Later steps (host type, documents) extend the same draft.
class HostSignupDraft {
  const HostSignupDraft({
    this.businessName = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.city = '',
  });

  final String businessName;
  final String contactPhone;
  final String contactEmail;
  final String city;

  HostSignupDraft copyWith({
    String? businessName,
    String? contactPhone,
    String? contactEmail,
    String? city,
  }) {
    return HostSignupDraft(
      businessName: businessName ?? this.businessName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      city: city ?? this.city,
    );
  }
}
