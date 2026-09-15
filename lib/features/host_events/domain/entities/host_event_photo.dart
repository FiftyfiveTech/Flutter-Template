/// An event cover photo already uploaded to the backend. [url] is a
/// short-lived, presigned link — never store or reuse it beyond the screen
/// that fetched it; only [id] is persisted (as part of an event's `photos`
/// list). Mirrors `HostVenuePhoto` from `host_venues`.
class HostEventPhoto {
  const HostEventPhoto({required this.id, required this.url});

  final String id;
  final String url;
}
