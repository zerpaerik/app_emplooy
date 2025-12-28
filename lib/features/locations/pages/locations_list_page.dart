import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../business/models/project_model.dart';
import '../../business/providers/locations_provider.dart';
import '../../contracts/pages/contracts_list_page.dart';
import '../widgets/location_card.dart';
import '../widgets/sub_locations_modal.dart';

class LocationsListPage extends ConsumerStatefulWidget {
  final Project project;

  const LocationsListPage({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<LocationsListPage> createState() => _LocationsListPageState();
}

class _LocationsListPageState extends ConsumerState<LocationsListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(locationsProvider.notifier).fetchLocations(widget.project.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    ref.read(locationsProvider.notifier).clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsState = ref.watch(locationsProvider);
    final filteredLocations = locationsState.filteredLocations;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Locations',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.project.name,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Project Info
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.05),
            child: Row(
              children: [
                Icon(Icons.business, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                      Text(
                        widget.project.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search locations...',
                prefixIcon: Icon(Icons.search, color: AppColors.textGrey),
                suffixIcon: locationsState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textGrey),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(locationsProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                ref.read(locationsProvider.notifier).updateSearch(value);
              },
            ),
          ),

          // Locations List
          Expanded(
            child: locationsState.isLoading && locationsState.locations.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : locationsState.error != null && locationsState.locations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              locationsState.error!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(locationsProvider.notifier).refreshLocations(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredLocations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: AppColors.textGrey),
                                const SizedBox(height: 16),
                                Text(
                                  'No locations found',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(locationsProvider.notifier).refreshLocations(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredLocations.length,
                              itemBuilder: (context, index) {
                                final location = filteredLocations[index];
                                return LocationCard(
                                  location: location,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ContractsListPage(
                                          location: location,
                                        ),
                                      ),
                                    );
                                  },
                                  onSubLocationsTap: location.hasSubLocations
                                      ? () {
                                          SubLocationsModal.show(
                                            context,
                                            location.subLocations!,
                                          );
                                        }
                                      : null,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
