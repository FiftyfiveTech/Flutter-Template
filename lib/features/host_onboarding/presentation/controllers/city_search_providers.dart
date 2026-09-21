import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/network_providers.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/city_repository.dart';
import '../../domain/usecases/get_cities.dart';
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
GetCitiesUseCase getCitiesUseCase(Ref ref) {
  return GetCitiesUseCase(ref.watch(cityRepositoryProvider));
}

/// Fetches every city once and keeps it alive for the rest of the session —
/// the H-01 signup and H-07 venue "City" fields both filter this cached
/// list locally instead of hitting the backend per keystroke.
@Riverpod(keepAlive: true)
Future<List<City>> allCities(Ref ref) async {
  final useCase = ref.watch(getCitiesUseCaseProvider);
  final result = await useCase();
  return result.when(ok: (cities) => cities, err: (_) => const []);
}

/// Filters the cached [allCitiesProvider] list by [query] (case-insensitive
/// substring match on name) for the "City" typeahead. An empty query
/// returns the full list, so opening the field with no input shows every
/// available city.
@riverpod
Future<List<City>> citySearchResults(Ref ref, String query) async {
  final cities = await ref.watch(allCitiesProvider.future);
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return cities;
  return cities
      .where((city) => city.name.toLowerCase().contains(trimmed))
      .toList();
}
