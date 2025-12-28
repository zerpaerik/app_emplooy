import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client.dart';
import '../../business/models/contract_model.dart';

class ContractsState {
  final bool isLoading;
  final List<Contract> contracts;
  final String? error;
  final int? locationId;

  const ContractsState({
    this.isLoading = false,
    this.contracts = const [],
    this.error,
    this.locationId,
  });

  ContractsState copyWith({
    bool? isLoading,
    List<Contract>? contracts,
    String? error,
    int? locationId,
  }) {
    return ContractsState(
      isLoading: isLoading ?? this.isLoading,
      contracts: contracts ?? this.contracts,
      error: error,
      locationId: locationId ?? this.locationId,
    );
  }
}

final contractsProvider = StateNotifierProvider<ContractsNotifier, ContractsState>((ref) {
  return ContractsNotifier();
});

class ContractsNotifier extends StateNotifier<ContractsState> {
  ContractsNotifier() : super(const ContractsState());

  final _httpClient = HttpClient.instance;

  Future<void> fetchContracts(int locationId) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        locationId: locationId,
      );

      final response = await _httpClient.get(
        '/api/v-1/contract/location/$locationId',
        requiresAuth: true,
      );

      if (_httpClient.isSuccessful(response)) {
        final data = _httpClient.parseResponseDynamic(response);
        if (data != null && data is List) {
          final contracts = (data as List)
              .map((json) => Contract.fromJson(json as Map<String, dynamic>))
              .toList();

          state = state.copyWith(
            isLoading: false,
            contracts: contracts,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load contracts',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<void> refreshContracts() async {
    if (state.locationId != null) {
      await fetchContracts(state.locationId!);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clear() {
    state = const ContractsState();
  }
}
