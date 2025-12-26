import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/city.dart';
import '../../models/movie.dart';
import '../../models/theatre.dart';
import '../../models/monitoring_task.dart';
import '../../providers/pvr_data_provider.dart';
import '../../widgets/searchable_dropdown.dart';

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

  // Date selection
  late DateSelectionType _dateType;
  late int _daysFromToday;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late List<DateTime> _specificDates;

  // Status
  late bool _statusAvailable;
  late bool _statusFilling;

  // Pending selections (for when data is loading)
  String? _pendingMovieId;
  String? _pendingTheatreId;

  @override
  void initState() {
    super.initState();

    if (widget.existingTask != null) {
      final task = widget.existingTask!;

      // Try to find city in available list
      _selectedCity = widget.cities
          .where((c) => c.id == task.cityId)
          .firstOrNull;

      if (_selectedCity == null && task.cityName != null) {
        // Fallback to name search if ID failed
        _selectedCity = widget.cities
            .where((c) => c.name == task.cityName)
            .firstOrNull;
      }

      // Fallback to checking by checking if any city matches roughly if strict match fails
      _selectedCity ??= widget.cities.firstOrNull;

      // Try to find movie in available list (might be empty if different city selected)
      _selectedMovie = widget.movies
          .where((m) => m.id == task.movieId)
          .firstOrNull;

      // If movie not found in current list, mark as pending
      if (_selectedMovie == null &&
          task.movieId != null &&
          task.movieId!.isNotEmpty) {
        _pendingMovieId = task.movieId;
      }

      // Try to find theatre
      _selectedTheatre = task.theatreId != null
          ? widget.theatres
                .where((t) => t.theatreId == task.theatreId)
                .firstOrNull
          : null;

      // If theatre not found but ID exists, mark as pending
      if (_selectedTheatre == null && task.theatreId != null) {
        _pendingTheatreId = task.theatreId;
      }

      _dateType = task.dateType;
      _daysFromToday = task.daysFromToday ?? 7;
      _startDate = task.startDate;
      _endDate = task.endDate;
      _specificDates = task.specificDates ?? [];
      _statusAvailable = task.statuses.contains('available');
      _statusFilling = task.statuses.contains('filling');

      // Trigger data loading if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_selectedCity != null) {
          final notifier = ref.read(pvrDataProvider.notifier);
          final currentState = ref.read(pvrDataProvider);

          // If the selected city isn't the active one in provider, select it to load movies
          if (currentState.selectedCity?.id != _selectedCity!.id) {
            notifier.selectCity(_selectedCity!);
          }
          // If city matches but we have a pending movie, ensure we have movies
          else if (_pendingMovieId != null && currentState.movies.isEmpty) {
            notifier.reloadMovies();
          }

          // If movie is already selected/found, load theatres if needed
          if (_selectedMovie != null) {
            if (currentState.selectedMovie?.id != _selectedMovie!.id) {
              notifier.selectMovie(_selectedMovie!);
            }
          }
        }
      });
    } else {
      _selectedCity = null; // null by default
      _selectedMovie = null; // null by default
      _selectedTheatre = null;
      _dateType = DateSelectionType.daysFromToday;
      _daysFromToday = 7;
      _startDate = null;
      _endDate = null;
      _specificDates = [];
      _statusAvailable = true;
      _statusFilling = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.existingTask != null;
    final pvrData = ref.watch(pvrDataProvider);

    // Listen for data updates to resolve pending selections
    ref.listen(pvrDataProvider, (previous, next) {
      // Resolve pending movie
      if (_pendingMovieId != null && next.movies.isNotEmpty) {
        final foundMovie = next.movies
            .where((m) => m.id == _pendingMovieId)
            .firstOrNull;

        if (foundMovie != null) {
          setState(() {
            _selectedMovie = foundMovie;
            _pendingMovieId = null;
          });
          // Load theatres for this movie
          ref.read(pvrDataProvider.notifier).selectMovie(foundMovie);
        }
      }

      // Resolve pending theatre
      if (_pendingTheatreId != null && next.theatres.isNotEmpty) {
        final foundTheatre = next.theatres
            .where((t) => t.theatreId == _pendingTheatreId)
            .firstOrNull;

        if (foundTheatre != null) {
          setState(() {
            _selectedTheatre = foundTheatre;
            _pendingTheatreId = null;
          });
        }
      }
    });

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
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _buildCityDropdown(pvrData),

                    const SizedBox(height: 24),

                    // Movie selection
                    _buildSectionHeader(
                      context,
                      Icons.movie,
                      'Select Movie',
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    if (_selectedCity == null)
                      _buildPlaceholder('Select a city first to see movies')
                    else if (pvrData.isLoading && pvrData.movies.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (pvrData.movies.isEmpty)
                      _buildPlaceholder('No movies available')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pvrData.movies.length} movies found',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildMovieDropdown(pvrData.movies),
                        ],
                      ),

                    if (_selectedMovie != null) ...[
                      const SizedBox(height: 12),
                      _buildMovieCard(_selectedMovie!),
                    ],

                    const SizedBox(height: 24),

                    // Theatre selection (optional)
                    _buildSectionHeader(
                      context,
                      Icons.theater_comedy,
                      'Select Theatre',
                      required: false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Optional - Leave empty to monitor all theatres',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedMovie == null)
                      _buildPlaceholder('Select a movie first')
                    else if (pvrData.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (pvrData.theatres.isEmpty)
                      _buildPlaceholder(
                        'No theatres found - try another movie or date',
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pvrData.theatres.length} theatres available',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTheatreDropdown(pvrData.theatres),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Date selection
                    _buildSectionHeader(
                      context,
                      Icons.calendar_today,
                      'Date Selection',
                    ),
                    const SizedBox(height: 12),
                    _buildDateTypeSelector(colorScheme),
                    const SizedBox(height: 16),
                    _buildDateConfig(colorScheme),

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
                      subtitle: 'Tickets are available for booking',
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                      value: _statusAvailable,
                      onChanged: (v) =>
                          setState(() => _statusAvailable = v ?? true),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusCheckbox(
                      title: 'Filling Up Fast',
                      subtitle: 'Limited tickets remaining',
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
                child: Column(
                  children: [
                    if (!_canSave())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Please select a city and movie to continue',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: _canSave() ? _save : null,
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? 'Update Task' : 'Create Task'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                  ],
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
    String title, {
    bool required = false,
  }) {
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
        if (required)
          Text(
            ' *',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildCityDropdown(PvrDataState pvrData) {
    return SearchableDropdown<City>(
      value: _selectedCity,
      hintText: 'Choose your city',
      searchHint: 'Search cities...',
      prefixIcon: Icons.location_on,
      items: pvrData.citiesByDistance,
      itemLabel: (city) => city.name,
      onChanged: (city) {
        if (city == null) return;
        setState(() {
          _selectedCity = city;
          _selectedMovie = null;
          _selectedTheatre = null;
        });
        ref.read(pvrDataProvider.notifier).selectCity(city);
      },
    );
  }

  Widget _buildMovieDropdown(List<Movie> movies) {
    return SearchableDropdown<Movie>(
      value: _selectedMovie,
      hintText: 'Choose a movie',
      searchHint: 'Search movies...',
      prefixIcon: Icons.movie,
      items: movies,
      itemLabel: (movie) => movie.name,
      onChanged: (movie) {
        if (movie == null) return;
        setState(() {
          _selectedMovie = movie;
          _selectedTheatre = null;
        });
        ref.read(pvrDataProvider.notifier).selectMovie(movie);
      },
    );
  }

  Widget _buildMovieCard(Movie movie) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Poster
          if (movie.posterUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                movie.posterUrl!,
                width: 60,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 90,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.movie),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 90,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.movie),
            ),

          const SizedBox(width: 12),

          // Movie info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (movie.runtime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.runtime!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                if (movie.genres.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    movie.genresText,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (movie.director != null && movie.director!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Dir: ${movie.director}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTheatreDropdown(List<Theatre> theatres) {
    return SearchableDropdown<Theatre?>(
      value: _selectedTheatre,
      hintText: 'All theatres (optional)',
      searchHint: 'Search theatres...',
      prefixIcon: Icons.theater_comedy,
      items: [null, ...theatres],
      itemLabel: (theatre) => theatre?.name ?? 'All Theatres',
      onChanged: (theatre) => setState(() => _selectedTheatre = theatre),
    );
  }

  Widget _buildDateTypeSelector(ColorScheme colorScheme) {
    return SegmentedButton<DateSelectionType>(
      segments: const [
        ButtonSegment(
          value: DateSelectionType.daysFromToday,
          label: Text('Days'),
          icon: Icon(Icons.today),
        ),
        ButtonSegment(
          value: DateSelectionType.dateRange,
          label: Text('Range'),
          icon: Icon(Icons.date_range),
        ),
        ButtonSegment(
          value: DateSelectionType.specificDates,
          label: Text('Specific'),
          icon: Icon(Icons.event),
        ),
      ],
      selected: {_dateType},
      onSelectionChanged: (selection) {
        setState(() => _dateType = selection.first);
      },
    );
  }

  Widget _buildDateConfig(ColorScheme colorScheme) {
    switch (_dateType) {
      case DateSelectionType.daysFromToday:
        return _buildDaysSelector(colorScheme);
      case DateSelectionType.dateRange:
        return _buildDateRangeSelector(colorScheme);
      case DateSelectionType.specificDates:
        return _buildSpecificDatesSelector(colorScheme);
    }
  }

  Widget _buildDaysSelector(ColorScheme colorScheme) {
    final today = DateTime.now();
    final endDate = today.add(Duration(days: _daysFromToday - 1));

    return Column(
      children: [
        Container(
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
                onPressed: _daysFromToday > 1
                    ? () => setState(() => _daysFromToday--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  '$_daysFromToday days',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _daysFromToday < 30
                    ? () => setState(() => _daysFromToday++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
                'From ${_formatDate(today)} to ${_formatDate(endDate)}',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                label: 'Start Date',
                date: _startDate,
                onTap: () => _pickDate(isStart: true),
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateButton(
                label: 'End Date',
                date: _endDate,
                onTap: () => _pickDate(isStart: false),
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        if (_startDate != null && _endDate != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_endDate!.difference(_startDate!).inDays + 1} days selected',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? _formatDate(date) : 'Select',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: date != null
                    ? colorScheme.onSurface
                    : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificDatesSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.tonalIcon(
          onPressed: _pickMultipleDates,
          icon: const Icon(Icons.add),
          label: const Text('Add Dates'),
        ),
        if (_specificDates.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _specificDates.map((date) {
              return Chip(
                label: Text(_formatDate(date)),
                onDeleted: () {
                  setState(() => _specificDates.remove(date));
                },
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }).toList(),
          ),
        ],
        if (_specificDates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No dates selected',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(picked)) {
            _startDate = picked;
          }
        }
      });
    }
  }

  Future<void> _pickMultipleDates() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null && !_specificDates.contains(picked)) {
      setState(() {
        _specificDates.add(picked);
        _specificDates.sort();
      });
    }
  }

  String _formatDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]}';
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
        (_statusAvailable || _statusFilling) &&
        _hasValidDates();
  }

  bool _hasValidDates() {
    switch (_dateType) {
      case DateSelectionType.daysFromToday:
        return _daysFromToday > 0;
      case DateSelectionType.dateRange:
        return _startDate != null && _endDate != null;
      case DateSelectionType.specificDates:
        return _specificDates.isNotEmpty;
    }
  }

  void _save() {
    final statuses = <String>[];
    if (_statusAvailable) statuses.add('available');
    if (_statusFilling) statuses.add('filling');

    final task = MonitoringTask(
      id: widget.existingTask?.id ?? '',
      cityId: _selectedCity!.id,
      cityName: _selectedCity!.name,
      movieId: _selectedMovie!.id,
      movieName: _selectedMovie!.name,
      moviePoster: _selectedMovie!.posterUrl,
      theatreId: _selectedTheatre?.theatreId,
      theatreName: _selectedTheatre?.name,
      dateType: _dateType,
      daysFromToday: _daysFromToday,
      startDate: _startDate,
      endDate: _endDate,
      specificDates: _specificDates.isNotEmpty ? _specificDates : null,
      statuses: statuses,
    );

    // Create new task with ID if needed
    if (task.id.isEmpty) {
      widget.onSave(
        MonitoringTask.create(
          cityId: task.cityId,
          cityName: task.cityName,
          movieId: task.movieId,
          movieName: task.movieName,
          moviePoster: task.moviePoster,
          theatreId: task.theatreId,
          theatreName: task.theatreName,
          dateType: task.dateType,
          daysFromToday: task.daysFromToday,
          startDate: task.startDate,
          endDate: task.endDate,
          specificDates: task.specificDates,
          statuses: task.statuses,
        ),
      );
    } else {
      widget.onSave(task);
    }
  }
}
