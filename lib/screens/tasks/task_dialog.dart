import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/city.dart';
import '../../models/movie.dart';
import '../../models/theatre.dart';
import '../../models/monitoring_task.dart';
import '../../providers/pvr_data_provider.dart';

/// Dialog for adding/editing monitoring tasks
class TaskDialog extends ConsumerStatefulWidget {
  final List<City> cities;
  final List<Movie> movies;
  final List<Theatre> theatres;
  final MonitoringTask? existingTask;
  final void Function(MonitoringTask task) onSave;

  const TaskDialog({
    super.key,
    required this.cities,
    required this.movies,
    required this.theatres,
    this.existingTask,
    required this.onSave,
  });

  @override
  ConsumerState<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends ConsumerState<TaskDialog> {
  late City? _selectedCity;
  late Movie? _selectedMovie;
  late Theatre? _selectedTheatre;
  late int _days;
  late bool _statusAvailable;
  late bool _statusFilling;

  @override
  void initState() {
    super.initState();

    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _selectedCity = widget.cities
          .where((c) => c.id == task.cityId)
          .firstOrNull;
      _selectedMovie = widget.movies
          .where((m) => m.id == task.movieId)
          .firstOrNull;
      _selectedTheatre = task.theatreId != null
          ? widget.theatres
                .where((t) => t.theatreId == task.theatreId)
                .firstOrNull
          : null;
      _days = task.days;
      _statusAvailable = task.statuses.contains('available');
      _statusFilling = task.statuses.contains('filling');
    } else {
      _selectedCity = widget.cities.isNotEmpty ? widget.cities.first : null;
      _selectedMovie = widget.movies.isNotEmpty ? widget.movies.first : null;
      _selectedTheatre = null;
      _days = 7;
      _statusAvailable = true;
      _statusFilling = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.existingTask != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit : Icons.add_task,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Task' : 'Add Monitoring Task',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Configure movie ticket monitoring',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Form content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // City selection
                    _buildSectionHeader(
                      context,
                      Icons.location_city,
                      'Select City',
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<City>(
                      value: _selectedCity,
                      items: widget.cities,
                      itemLabel: (city) => city.name,
                      onChanged: (city) {
                        setState(() => _selectedCity = city);
                        if (city != null) {
                          ref
                              .read(pvrDataProvider.notifier)
                              .changeCity(city.name);
                        }
                      },
                      hint: 'Select a city',
                    ),

                    const SizedBox(height: 24),

                    // Movie selection
                    _buildSectionHeader(context, Icons.movie, 'Select Movie'),
                    const SizedBox(height: 12),
                    _buildDropdown<Movie>(
                      value: _selectedMovie,
                      items: widget.movies,
                      itemLabel: (movie) => movie.name,
                      onChanged: (movie) {
                        setState(() => _selectedMovie = movie);
                        if (movie != null) {
                          ref
                              .read(pvrDataProvider.notifier)
                              .loadTheatresForMovie(movie.id);
                        }
                      },
                      hint: 'Select a movie',
                    ),

                    const SizedBox(height: 24),

                    // Theatre selection (optional)
                    _buildSectionHeader(
                      context,
                      Icons.theater_comedy,
                      'Select Theatre (Optional)',
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<Theatre?>(
                      value: _selectedTheatre,
                      items: [null, ...widget.theatres],
                      itemLabel: (theatre) =>
                          theatre?.name ??
                          '🔍 All Theatres (monitor everywhere)',
                      onChanged: (theatre) =>
                          setState(() => _selectedTheatre = theatre),
                      hint: 'Select a theatre',
                    ),

                    const SizedBox(height: 24),

                    // Days selection
                    _buildSectionHeader(
                      context,
                      Icons.calendar_today,
                      'Days to Monitor',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How many days from today should we monitor?',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDaysSelector(colorScheme),
                    const SizedBox(height: 8),
                    _buildDatePreview(colorScheme),

                    const SizedBox(height: 24),

                    // Status filter
                    _buildSectionHeader(
                      context,
                      Icons.notifications_active,
                      'Notify When Status Is',
                    ),
                    const SizedBox(height: 12),
                    _buildStatusCheckbox(
                      title: 'Available',
                      subtitle: 'Tickets are available',
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                      value: _statusAvailable,
                      onChanged: (v) =>
                          setState(() => _statusAvailable = v ?? true),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusCheckbox(
                      title: 'Filling Up Fast',
                      subtitle: 'Limited tickets left',
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      value: _statusFilling,
                      onChanged: (v) =>
                          setState(() => _statusFilling = v ?? true),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Save button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: FilledButton.icon(
                  onPressed: _canSave() ? _save : null,
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? 'Update Task' : 'Create Task'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    required String hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Widget _buildDaysSelector(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _days > 1 ? () => setState(() => _days--) : null,
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Text(
              '$_days days',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: _days < 30 ? () => setState(() => _days++) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePreview(ColorScheme colorScheme) {
    final today = DateTime.now();
    final endDate = today.add(Duration(days: _days - 1));
    String dateFormat(DateTime d) => '${d.day} ${_monthName(d.month)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'From ${dateFormat(today)} to ${dateFormat(endDate)} ${endDate.year}',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildStatusCheckbox({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required void Function(bool?) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: value
            ? colorScheme.primaryContainer.withValues(alpha: 0.2)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        subtitle: Text(subtitle),
        controlAffinity: ListTileControlAffinity.trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool _canSave() {
    return _selectedCity != null &&
        _selectedMovie != null &&
        (_statusAvailable || _statusFilling);
  }

  void _save() {
    final statuses = <String>[];
    if (_statusAvailable) statuses.add('available');
    if (_statusFilling) statuses.add('filling');

    final task = MonitoringTask(
      id: widget.existingTask?.id,
      cityId: _selectedCity!.id,
      cityName: _selectedCity!.name,
      movieId: _selectedMovie!.id,
      movieName: _selectedMovie!.name,
      theatreId: _selectedTheatre?.theatreId,
      theatreName: _selectedTheatre?.name ?? 'All Theatres',
      days: _days,
      statuses: statuses,
    );

    widget.onSave(task);
  }
}
