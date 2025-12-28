import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client.dart';
import '../models/project_model.dart';

/// Estado del Projects Provider
class ProjectsState {
  final bool isLoading;
  final List<Project> projects;
  final String? error;
  final String searchQuery;

  const ProjectsState({
    this.isLoading = false,
    this.projects = const [],
    this.error,
    this.searchQuery = '',
  });

  ProjectsState copyWith({
    bool? isLoading,
    List<Project>? projects,
    String? error,
    String? searchQuery,
  }) {
    return ProjectsState(
      isLoading: isLoading ?? this.isLoading,
      projects: projects ?? this.projects,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Project> get filteredProjects {
    if (searchQuery.isEmpty) return projects;
    
    return projects.where((project) {
      final query = searchQuery.toLowerCase();
      return project.name.toLowerCase().contains(query) ||
             project.customer.toLowerCase().contains(query);
    }).toList();
  }
}

/// Provider de Projects
final projectsProvider = StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  return ProjectsNotifier();
});

class ProjectsNotifier extends StateNotifier<ProjectsState> {
  ProjectsNotifier() : super(const ProjectsState());

  final _httpClient = HttpClient.instance;

  /// Obtener lista de proyectos desde el servidor
  Future<void> fetchProjects() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _httpClient.get(
        '/api/v-1/project',
        requiresAuth: true,
      );

      if (_httpClient.isSuccessful(response)) {
        final data = _httpClient.parseResponseDynamic(response);
        if (data != null && data is List) {
          final projects = (data as List)
              .map((json) => Project.fromJson(json as Map<String, dynamic>))
              .toList();
          
          state = state.copyWith(
            isLoading: false,
            projects: projects,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load projects',
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

  /// Refrescar proyectos
  Future<void> refreshProjects() async {
    await fetchProjects();
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
