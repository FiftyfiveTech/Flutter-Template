import '../../domain/entities/city.dart';

class CityDto {
  const CityDto({
    required this.id,
    required this.city,
    required this.state,
    required this.country,
  });

  final String id;
  final String city;
  final String state;
  final String country;

  factory CityDto.fromJson(Map<String, dynamic> json) {
    return CityDto(
      id: json['id'] as String,
      city: json['city'] as String,
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
    );
  }

  City toEntity() => City(id: id, name: city, state: state, country: country);
}
