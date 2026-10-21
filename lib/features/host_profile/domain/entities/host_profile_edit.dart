/// The fields a host may change via Edit profile (`PATCH
/// /api/v1/host/profile`). A `null` field is left unchanged on the server.
///
/// [photoSourcePath] is a just-picked image on disk — it's copied into
/// private storage and uploaded, never persisted as-is.
class HostProfileEdit {
  const HostProfileEdit({
    this.firstName,
    this.lastName,
    this.businessName,
    this.photoSourcePath,
  });

  final String? firstName;
  final String? lastName;
  final String? businessName;
  final String? photoSourcePath;

  bool get isEmpty =>
      firstName == null &&
      lastName == null &&
      businessName == null &&
      photoSourcePath == null;
}
