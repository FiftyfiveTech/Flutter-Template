/// Basics collected on H-01 · Signup, the first step of the host onboarding
/// wizard. Later steps (host type, documents) extend the same draft.
class HostSignupDraft {
  const HostSignupDraft({
    this.businessName = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.city = '',
    this.cityId = '',
  });

  final String businessName;
  final String contactPhone;
  final String contactEmail;

  /// Display name of the selected city (from the H-01 typeahead).
  final String city;

  /// The backend city id backing [city] — required by the signup API's
  /// `cityId` field. Only populated once a real search result is picked,
  /// never guessed from [city] alone.
  final String cityId;

  HostSignupDraft copyWith({
    String? businessName,
    String? contactPhone,
    String? contactEmail,
    String? city,
    String? cityId,
  }) {
    return HostSignupDraft(
      businessName: businessName ?? this.businessName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      city: city ?? this.city,
      cityId: cityId ?? this.cityId,
    );
  }
}
