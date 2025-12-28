import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client.dart';
import '../models/crew_model.dart';

class CrewState {
  final bool isLoading;
  final CrewSheet? currentCrew;
  final List<CrewSheet> crewSheets;
  final List<Worker> workers;
  final String? error;
  final int? locationId;

  const CrewState({
    this.isLoading = false,
    this.currentCrew,
    this.crewSheets = const [],
    this.workers = const [],
    this.error,
    this.locationId,
  });

  CrewState copyWith({
    bool? isLoading,
    CrewSheet? currentCrew,
    List<CrewSheet>? crewSheets,
    List<Worker>? workers,
    String? error,
    int? locationId,
  }) {
    return CrewState(
      isLoading: isLoading ?? this.isLoading,
      currentCrew: currentCrew ?? this.currentCrew,
      crewSheets: crewSheets ?? this.crewSheets,
      workers: workers ?? this.workers,
      error: error,
      locationId: locationId ?? this.locationId,
    );
  }
}

final crewProvider = StateNotifierProvider<CrewNotifier, CrewState>((ref) {
  return CrewNotifier();
});

class CrewNotifier extends StateNotifier<CrewState> {
  CrewNotifier() : super(const CrewState());

  final _httpClient = HttpClient.instance;

  Future<void> fetchCurrentCrew() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _httpClient.get(
        '/api/v-1/crew/current',
        requiresAuth: true,
      );

      if (_httpClient.isSuccessful(response)) {
        final data = _httpClient.parseResponseDynamic(response);
        if (data != null && data is Map) {
          final crew = CrewSheet.fromJson(data as Map<String, dynamic>);
          state = state.copyWith(
            isLoading: false,
            currentCrew: crew,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          currentCrew: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<void> fetchCrewSheets(int locationId) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        locationId: locationId,
      );

      final response = await _httpClient.get(
        '/api/v-1/crew/$locationId/report',
        requiresAuth: true,
      );

      if (_httpClient.isSuccessful(response)) {
        final data = _httpClient.parseResponse(response);
        if (data != null && data is List) {
          final crewSheets = (data as List)
              .map((json) => CrewSheet.fromJson(json as Map<String, dynamic>))
              .toList();

          state = state.copyWith(
            isLoading: false,
            crewSheets: crewSheets,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load crew sheets',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<void> fetchWorkers(int locationId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _httpClient.get(
        '/api/v-1/crew/$locationId/workers',
        requiresAuth: true,
      );

      if (_httpClient.isSuccessful(response)) {
        final data = _httpClient.parseResponse(response);
        if (data != null && data is List) {
          final workers = (data as List)
              .map((json) => Worker.fromJson(json as Map<String, dynamic>))
              .toList();

          state = state.copyWith(
            isLoading: false,
            workers: workers,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load workers',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<bool> endCheckIn(int crewId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _httpClient.post(
        '/api/v-1/crew/$crewId/end-in',
        body: {},
        requiresAuth: true,
      );

      if (_httpClient.isSuccessful(response)) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not end check-in',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clear() {
    state = const CrewState();
  }
}
