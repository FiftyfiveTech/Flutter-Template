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
    // No real GET /api/v1/host/home-summary endpoint exists yet — this
    // used to return hardcoded demo data (a fake org name, a "verified"
    // badge, and 3 fake events), which meant the home screen showed fake
    // content even fully offline, since this call never actually touches
    // the network and so can never fail. It now returns honest empty
    // defaults instead; `HostHomeController.loadSummary` overwrites
    // savedVenuesCount/events with the real venues/events APIs when they
    // succeed, and leaves these empty defaults in place — never fake
    // data — when the device has no connection.
    return const HostHomeSummaryDto(
      hostName: '',
      isVerified: false,
      savedVenuesCount: 0,
      events: [],
    );
  }
}
