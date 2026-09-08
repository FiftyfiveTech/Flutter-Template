import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/network_providers.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/city_repository.dart';
import '../../domain/usecases/search_cities.dart';
import '../../data/datasources/city_remote_datasource.dart';
import '../../data/repository_impl/city_repository_impl.dart';

part 'city_search_providers.g.dart';

@riverpod
CityRemoteDatasource cityRemoteDatasource(Ref ref) {
  return CityRestDatasource(ref.watch(baseApiClientProvider));
}

@riverpod
CityRepository cityRepository(Ref ref) {
  return CityRepositoryImpl(ref.watch(cityRemoteDatasourceProvider));
}

@riverpod
SearchCitiesUseCase searchCitiesUseCase(Ref ref) {
  return SearchCitiesUseCase(ref.watch(cityRepositoryProvider));
}

/// Runs a single city search for the H-01 signup "City" typeahead.
/// Autodisposed per query — the widget layer debounces keystrokes before
/// invoking this.
@riverpod
Future<List<City>> citySearchResults(Ref ref, String query) async {
  if (query.trim().isEmpty) return const [];
  final useCase = ref.watch(searchCitiesUseCaseProvider);
  final result = await useCase(query);
  return result.when(ok: (cities) => cities, err: (_) => const []);
}
