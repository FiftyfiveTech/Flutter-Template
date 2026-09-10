/// The kind of host signing up, from `host-app/01-host-onboarding.md` §1.
/// Drives which documents H-03 asks for: venues carry the heavier set
/// (address proof, FSSAI, excise licence) that the others skip.
enum HostType { club, community, venue, individualOperator }

/// Display label shared between H-02 (selection) and H-03 (recap badge) so
/// the two screens can't drift on wording.
extension HostTypeLabel on HostType {
  String get label => switch (this) {
    HostType.club => 'Club',
    HostType.community => 'Community',
    HostType.venue => 'Venue',
    HostType.individualOperator => 'Individual operator',
  };

  /// Value sent as `hostType` to `POST /api/v1/host/submit-verification`.
  String get apiValue => switch (this) {
    HostType.club => 'club',
    HostType.community => 'community',
    HostType.venue => 'venue',
    HostType.individualOperator => 'individual_operator',
  };
}
