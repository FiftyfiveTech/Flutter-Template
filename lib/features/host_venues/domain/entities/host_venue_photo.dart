/// A venue photo already uploaded to the backend. [url] is a short-lived,
/// presigned link — never store or reuse it beyond the screen that fetched
/// it; only [id] is persisted (as part of a venue's `photos` list).
class HostVenuePhoto {
  const HostVenuePhoto({required this.id, required this.url});

  final String id;
  final String url;
}
