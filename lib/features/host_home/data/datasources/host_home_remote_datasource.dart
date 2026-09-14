import '../../../../core/network/base_api_client.dart';
import '../models/host_home_dto.dart';

abstract class HostHomeRemoteDatasource {
  Future<HostHomeSummaryDto> getHomeSummary();
}

class HostHomeRestDatasource implements HostHomeRemoteDatasource {
  const HostHomeRestDatasource(this._client);

  // ignore: unused_field
  final BaseApiClient _client;

  @override
  Future<HostHomeSummaryDto> getHomeSummary() async {
    // In production, this calls GET /api/v1/host/home-summary.
    // For now, it provides initial seed data matching the design system.
    return const HostHomeSummaryDto(
      hostName: 'Cellar Door Collective',
      isVerified: true,
      savedVenuesCount: 2,
      events: [
        HostHomeEventDto(
          id: 'evt-1',
          title: 'Blind Wine & Bad Takes',
          formattedSchedule: 'Thu, 12 Sep · 8:00 PM · Toit, Indiranagar',
          status: 'upcoming',
          soldCount: 12,
          capacity: 32,
        ),
        HostHomeEventDto(
          id: 'evt-2',
          title: 'Pottery & Small Talk',
          formattedSchedule: 'Sat, 14 Sep · 6:30 PM · Vasanth Nagar',
          status: 'draft',
          soldCount: 8,
          capacity: 24,
        ),
        HostHomeEventDto(
          id: 'evt-3',
          title: 'Board Game Night',
          formattedSchedule: 'Sun, 30 Aug · 7:00 PM · Koramangala',
          status: 'completed',
          soldCount: 28,
          capacity: 28,
        ),
      ],
    );
  }
}
