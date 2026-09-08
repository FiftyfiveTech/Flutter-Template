/// The kind of host signing up, from `host-app/01-host-onboarding.md` §1.
/// Drives which documents H-03 asks for: venues carry the heavier set
/// (address proof, FSSAI, excise licence) that the others skip.
enum HostType { club, community, venue, individualOperator }
