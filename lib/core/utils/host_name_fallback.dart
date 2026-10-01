/// The home-summary endpoint's hostName is placeholder seed data (no real
/// backend field for it yet) — fall back to the business name saved
/// locally at H-01 signup, if any, when it's empty.
String resolveHostName(String hostName, String sessionBusinessName) {
  return hostName.isEmpty ? sessionBusinessName : hostName;
}
