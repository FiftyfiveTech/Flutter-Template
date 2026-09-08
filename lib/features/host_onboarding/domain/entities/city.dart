/// A city returned by the cities search API, used to populate the H-01
/// signup "City" typeahead.
class City {
  const City({
    required this.id,
    required this.name,
    required this.state,
    required this.country,
  });

  final String id;
  final String name;
  final String state;
  final String country;
}
