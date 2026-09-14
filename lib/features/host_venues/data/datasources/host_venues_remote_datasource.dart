import '../../../../core/network/base_api_client.dart';
import '../models/host_venue_dto.dart';

abstract class HostVenuesRemoteDatasource {
  Future<List<HostVenueDto>> getVenues();

  Future<HostVenueDto> saveVenue(HostVenueDto venue);

  Future<void> deleteVenue(String venueId);
}

/// In-memory seed data standing in for `/api/v1/host/venues` until a real
/// backend endpoint exists — mirrors `HostHomeRestDatasource`'s placeholder
/// pattern. Mutations are held in [_seedVenues] for the lifetime of the app
/// session so H-06/H-07 behave consistently across navigation.
class HostVenuesRestDatasource implements HostVenuesRemoteDatasource {
  HostVenuesRestDatasource(this._client);

  // ignore: unused_field
  final BaseApiClient _client;

  static final List<HostVenueDto> _seedVenues = [
    const HostVenueDto(
      id: 'venue-1',
      name: 'Toit, Indiranagar',
      addressLine1: '12, 100 Feet Road',
      addressLine2: 'Indiranagar',
      city: 'Bangalore',
      pincode: '560038',
      maxCapacity: 40,
      eventTypes: ['House party', 'Rooftop'],
      photoPaths: [],
    ),
    const HostVenueDto(
      id: 'venue-2',
      name: 'The Yard, Koramangala',
      addressLine1: '5th Block',
      addressLine2: 'Koramangala',
      city: 'Bangalore',
      pincode: '560095',
      maxCapacity: 60,
      eventTypes: ['Warehouse', 'Bar takeover'],
      photoPaths: [],
    ),
  ];

  @override
  Future<List<HostVenueDto>> getVenues() async {
    // In production, this calls GET /api/v1/host/venues.
    return List.unmodifiable(_seedVenues);
  }

  @override
  Future<HostVenueDto> saveVenue(HostVenueDto venue) async {
    // In production, this calls POST /api/v1/host/venues (add) or
    // PUT /api/v1/host/venues/{id} (edit).
    final existingIndex = _seedVenues.indexWhere((v) => v.id == venue.id);
    if (existingIndex >= 0) {
      _seedVenues[existingIndex] = venue;
      return venue;
    }
    final saved = HostVenueDto(
      id: 'venue-${DateTime.now().microsecondsSinceEpoch}',
      name: venue.name,
      addressLine1: venue.addressLine1,
      addressLine2: venue.addressLine2,
      city: venue.city,
      pincode: venue.pincode,
      maxCapacity: venue.maxCapacity,
      eventTypes: venue.eventTypes,
      photoPaths: venue.photoPaths,
    );
    _seedVenues.add(saved);
    return saved;
  }

  @override
  Future<void> deleteVenue(String venueId) async {
    // In production, this calls DELETE /api/v1/host/venues/{id}.
    _seedVenues.removeWhere((v) => v.id == venueId);
  }
}
