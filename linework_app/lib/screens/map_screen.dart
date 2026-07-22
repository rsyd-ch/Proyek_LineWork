import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/screens/detail_screen.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:linework_app/services/location_service.dart';

const _brandColor = Color(0xFF0B4778);
const _defaultCenter = LatLng(-6.2, 106.816666);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  double _radiusKm = 5;
  bool _codOnly = false;
  bool _isLoadingLocation = true;
  bool _locationUnavailable = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationUnavailable = false;
    });

    final position = await LocationService.getCurrentLocation();
    if (!mounted) return;

    if (position == null) {
      setState(() {
        _isLoadingLocation = false;
        _locationUnavailable = true;
      });
      return;
    }

    final nextLocation = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentLocation = nextLocation;
      _isLoadingLocation = false;
    });

    await _moveCamera(nextLocation, zoom: 14);
  }

  Future<void> _moveCamera(LatLng target, {double zoom = 13}) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void _openTask(TaskModel task) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DetailScreen(task: task)));
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    final openTasks = tasks.where((task) {
      final hasLocation =
          task.location.latitude != 0 || task.location.longitude != 0;
      final matchesCod = !_codOnly || task.isCod;
      return task.status == 'open' && hasLocation && matchesCod;
    }).toList();

    final currentLocation = _currentLocation;
    if (currentLocation == null) {
      return openTasks;
    }

    openTasks.sort((a, b) {
      final distanceA = _distanceFromCurrent(a);
      final distanceB = _distanceFromCurrent(b);
      return distanceA.compareTo(distanceB);
    });

    return openTasks
        .where((task) => _distanceFromCurrent(task) <= _radiusKm * 1000)
        .toList();
  }

  double _distanceFromCurrent(TaskModel task) {
    final currentLocation = _currentLocation;
    if (currentLocation == null) return double.infinity;

    return LocationService.calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      task.location.latitude,
      task.location.longitude,
    );
  }

  Set<Marker> _buildMarkers(List<TaskModel> tasks) {
    final markers = <Marker>{};
    final currentLocation = _currentLocation;

    if (currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current-location'),
          position: currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
        ),
      );
    }

    for (final task in tasks) {
      markers.add(
        Marker(
          markerId: MarkerId(task.id),
          position: LatLng(task.location.latitude, task.location.longitude),
          infoWindow: InfoWindow(
            title: task.title,
            snippet: _formatPrice(task.price),
          ),
          onTap: () => _moveCamera(
            LatLng(task.location.latitude, task.location.longitude),
            zoom: 15,
          ),
        ),
      );
    }

    return markers;
  }

  String _formatPrice(num price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  String _formatDistance(TaskModel task) {
    final distance = _distanceFromCurrent(task);
    if (distance.isInfinite) return 'Jarak belum tersedia';
    if (distance < 1000) return '${distance.round()} m';
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = _currentLocation ?? _defaultCenter;

    return StreamBuilder<List<TaskModel>>(
      stream: FirestoreService.streamTasksFiltered(),
      builder: (context, snapshot) {
        final tasks = _filterTasks(snapshot.data ?? []);
        final markers = _buildMarkers(tasks);

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: _currentLocation == null ? 11 : 14,
              ),
              padding: const EdgeInsets.only(top: 152, bottom: 238),
              markers: markers,
              circles: _currentLocation == null
                  ? const <Circle>{}
                  : {
                      Circle(
                        circleId: const CircleId('task-radius'),
                        center: _currentLocation!,
                        radius: _radiusKm * 1000,
                        fillColor: _brandColor.withValues(alpha: 0.10),
                        strokeColor: _brandColor.withValues(alpha: 0.35),
                        strokeWidth: 2,
                      ),
                    },
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: _MapControlPanel(
                  radiusKm: _radiusKm,
                  codOnly: _codOnly,
                  taskCount: tasks.length,
                  isLoadingLocation: _isLoadingLocation,
                  locationUnavailable: _locationUnavailable,
                  hasFirestoreError: snapshot.hasError,
                  onRadiusChanged: (value) {
                    setState(() {
                      _radiusKm = value;
                    });
                  },
                  onCodChanged: (value) {
                    setState(() {
                      _codOnly = value;
                    });
                  },
                  onRefreshLocation: _loadCurrentLocation,
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 220,
              child: _MapActionButton(
                tooltip: 'Pusatkan lokasi',
                icon: _isLoadingLocation ? null : Icons.my_location,
                onPressed: _isLoadingLocation
                    ? null
                    : () {
                        final location = _currentLocation;
                        if (location == null) {
                          _loadCurrentLocation();
                          return;
                        }
                        _moveCamera(location, zoom: 14);
                      },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 88,
              child: _TaskPreviewStrip(
                tasks: tasks,
                isLoading: snapshot.connectionState == ConnectionState.waiting,
                priceBuilder: _formatPrice,
                distanceBuilder: _formatDistance,
                onTaskTap: _openTask,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapControlPanel extends StatelessWidget {
  final double radiusKm;
  final bool codOnly;
  final int taskCount;
  final bool isLoadingLocation;
  final bool locationUnavailable;
  final bool hasFirestoreError;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<bool> onCodChanged;
  final VoidCallback onRefreshLocation;

  const _MapControlPanel({
    required this.radiusKm,
    required this.codOnly,
    required this.taskCount,
    required this.isLoadingLocation,
    required this.locationUnavailable,
    required this.hasFirestoreError,
    required this.onRadiusChanged,
    required this.onCodChanged,
    required this.onRefreshLocation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 8,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.map_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peta pekerjaan',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$taskCount pekerjaan tersedia',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Perbarui lokasi',
                  onPressed: isLoadingLocation ? null : onRefreshLocation,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    fixedSize: const Size(38, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: isLoadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.gps_fixed),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RadiusSelector(
                    value: radiusKm,
                    onChanged: onRadiusChanged,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 82,
                  height: 38,
                  child: Tooltip(
                    message: 'Hanya COD',
                    child: FilterChip(
                      selected: codOnly,
                      label: const Text('COD'),
                      avatar: const Icon(Icons.payments_outlined, size: 16),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: onCodChanged,
                    ),
                  ),
                ),
              ],
            ),
            if (locationUnavailable || hasFirestoreError) ...[
              const SizedBox(height: 10),
              _MapNotice(
                message: hasFirestoreError
                    ? 'Data pekerjaan belum bisa dimuat.'
                    : 'Lokasi belum aktif. Peta memakai area Jakarta.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RadiusSelector extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _RadiusSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const options = [3.0, 5.0, 10.0];

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var index = 0; index < options.length; index++) ...[
            Expanded(
              child: _RadiusOption(
                label: '${options[index].toStringAsFixed(0)} km',
                selected: value == options[index],
                onTap: () => onChanged(options[index]),
              ),
            ),
            if (index != options.length - 1)
              Container(width: 1, color: colorScheme.outline),
          ],
        ],
      ),
    );
  }
}

class _RadiusOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadiusOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        color: selected ? colorScheme.primaryContainer : colorScheme.surface,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  final String message;

  const _MapNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 17, color: Color(0xFFF59E0B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF92400E),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final String tooltip;
  final IconData? icon;
  final VoidCallback? onPressed;

  const _MapActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: FloatingActionButton.small(
        heroTag: 'map-location-button',
        onPressed: onPressed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        child: icon == null
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
      ),
    );
  }
}

class _TaskPreviewStrip extends StatelessWidget {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String Function(num price) priceBuilder;
  final String Function(TaskModel task) distanceBuilder;
  final ValueChanged<TaskModel> onTaskTap;

  const _TaskPreviewStrip({
    required this.tasks,
    required this.isLoading,
    required this.priceBuilder,
    required this.distanceBuilder,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _TaskStripState(
        icon: Icons.sync,
        title: 'Memuat pekerjaan terdekat...',
      );
    }

    if (tasks.isEmpty) {
      return const _TaskStripState(
        icon: Icons.location_off_outlined,
        title: 'Belum ada pekerjaan di radius ini',
      );
    }

    return SizedBox(
      height: 118,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _TaskPreviewCard(
            task: task,
            price: priceBuilder(task.price),
            distance: distanceBuilder(task),
            onTap: () => onTaskTap(task),
          );
        },
      ),
    );
  }
}

class _TaskStripState extends StatelessWidget {
  final IconData icon;
  final String title;

  const _TaskStripState({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Material(
        color: colorScheme.surface,
        elevation: 6,
        shadowColor: const Color(0x22000000),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 74,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskPreviewCard extends StatelessWidget {
  final TaskModel task;
  final String price;
  final String distance;
  final VoidCallback onTap;

  const _TaskPreviewCard({
    required this.task,
    required this.price,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 258,
      child: Material(
        color: colorScheme.surface,
        elevation: 7,
        shadowColor: const Color(0x22000000),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      price,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  task.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TaskMetaChip(
                      icon: Icons.near_me_outlined,
                      label: distance,
                    ),
                    _TaskMetaChip(
                      icon: Icons.category_outlined,
                      label: task.category,
                    ),
                    _TaskMetaChip(
                      icon: Icons.payments_outlined,
                      label: task.isCod ? 'COD' : 'Transfer',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TaskMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
