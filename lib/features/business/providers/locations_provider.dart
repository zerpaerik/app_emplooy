import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client.dart';
import '../models/location_model.dart';

/// Estado del Locations Provider
class LocationsState {
  final bool isLoading;
  final List<Location> locations;
  final String? error;
  final String searchQuery;
  final int? projectId;

  const LocationsState({
    this.isLoading = false,
    this.locations = const [],
    this.error,
    this.searchQuery = '',
    this.projectId,
  });

  LocationsState copyWith({
    bool? isLoading,
    List<Location>? locations,
    String? error,
    String? searchQuery,
    int? projectId,
  }) {
    return LocationsState(
      isLoading: isLoading ?? this.isLoading,
      locations: locations ?? this.locations,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      projectId: projectId ?? this.projectId,
    );
  }

  List<Location> get filteredLocations {
    if (searchQuery.isEmpty) return locations;
    
    return locations.where((location) {
      final query = searchQuery.toLowerCase();
      return location.name.toLowerCase().contains(query) ||
             location.firstAddress.toLowerCase().contains(query);
    }).toList();
  }
}

/// Provider de Locations
final locationsProvider = StateNotifierProvider<LocationsNotifier, LocationsState>((ref) {
  return LocationsNotifier();
});

class LocationsNotifier extends StateNotifier<LocationsState> {
  LocationsNotifier() : super(const LocationsState());

  final _httpClient = HttpClient.instance;

  /// Obtener ubicaciones de un proyecto desde el servidor
  Future<void> fetchLocations(int projectId) async {
    try {
      state = state.copyWith(
        isLoading: true, 
        error: null,
        projectId: projectId,
      );

      final response = await _httpClient.get(
        '/api/v-1/project/$projectId/location',
        requiresAuth: true,
      );

      if (_httpClient.isSuccessful(response)) {
        final data = _httpClient.parseResponse(response);
        if (data != null && data is List) {
          final locations = (data as List)
              .map((json) => Location.fromJson(json as Map<String, dynamic>))
              .toList();
          
          state = state.copyWith(
            isLoading: false,
            locations: locations,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load locations',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Actualizar búsqueda
  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Limpiar búsqueda
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  /// Refrescar ubicaciones
  Future<void> refreshLocations() async {
    if (state.projectId != null) {
      await fetchLocations(state.projectId!);
    }
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Limpiar estado
  void clear() {
    state = const LocationsState();
  }
}
