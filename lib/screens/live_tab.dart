import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/live_status_provider.dart';
import '../../models/show_session.dart';

class LiveTab extends ConsumerStatefulWidget {
  const LiveTab({super.key});

  @override
  ConsumerState<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends ConsumerState<LiveTab> {
  @override
  void initState() {
    super.initState();
    // Auto-refresh when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveStatusProvider.notifier).refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Group all sessions from all tasks by date, then by theatre
    final sessionsByDate = <String, Map<String, List<ShowSession>>>{};
    final dateLabels = <String, String>{}; // Maps YYYY-MM-DD to "Jan 15"

    for (final status in liveState.taskStatuses) {
      for (final session in status.sessions) {
        final date = session.showDate;
        dateLabels[date] = session.formattedDate;

        final dateMap = sessionsByDate.putIfAbsent(date, () => {});
        dateMap.putIfAbsent(session.theatreName, () => []).add(session);
      }
    }

    final sortedDates = sessionsByDate.keys.toList()..sort();

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(context, colorScheme, liveState),

          if (liveState.error != null)
            _buildErrorBanner(colorScheme, liveState),

          // Content
          Expanded(
            child: sortedDates.isEmpty
                ? (liveState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildEmptyState(context, colorScheme))
                : DefaultTabController(
                    length: sortedDates.length,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: sortedDates.map((date) {
                            return Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(dateLabels[date]!),
                                  const SizedBox(width: 6),
                                  _buildDateBatchCount(
                                    colorScheme,
                                    sessionsByDate[date]!,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: sortedDates.map((date) {
                              final theatres = sessionsByDate[date]!;
                              final sortedTheatres = theatres.keys.toList()
                                ..sort();

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                itemCount: sortedTheatres.length,
                                itemBuilder: (context, idx) {
                                  final theatreName = sortedTheatres[idx];
                                  final sessions = theatres[theatreName]!;
                                  return _TheatreCard(
                                    name: theatreName,
                                    sessions: sessions,
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    LiveStatusState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE STATUS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time cinema sessions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          IconButton.filledTonal(
            onPressed: state.isLoading
                ? null
                : () => ref.read(liveStatusProvider.notifier).refreshAll(),
            icon: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh All',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ColorScheme colorScheme, LiveStatusState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.error!,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBatchCount(
    ColorScheme colorScheme,
    Map<String, List<ShowSession>> theatres,
  ) {
    int totalAvailable = 0;
    for (final sessions in theatres.values) {
      totalAvailable += sessions
          .where((s) => s.isAvailable || s.isFilling)
          .length;
    }

    if (totalAvailable == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$totalAvailable',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_seat_outlined,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Available Sessions Found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your task settings or refresh',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TheatreCard extends StatelessWidget {
  final String name;
  final List<ShowSession> sessions;

  const _TheatreCard({required this.name, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Filter sessions by availability if needed, but here we show all for the card
    final availableCount = sessions
        .where((s) => s.isAvailable || s.isFilling)
        .length;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theatre Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.theater_comedy_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (availableCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$availableCount SHOWS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Movie Groups (in case multiple movies are tracked for same theatre)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: _buildMovieGroups(context)),
          ),

          const Divider(height: 1),

          // Footer Action
          InkWell(
            onTap: () {
              if (sessions.isNotEmpty) {
                launchUrl(
                  Uri.parse(sessions.first.bookingUrl),
                  mode: LaunchMode.externalApplication,
                );
              } else {
                launchUrl(
                  Uri.parse('https://www.pvrcinemas.com'),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Open Booking Page',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 14, color: colorScheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMovieGroups(BuildContext context) {
    final movieGroups = <String, List<ShowSession>>{};
    for (final session in sessions) {
      final movie = session.movieName ?? 'Unknown Movie';
      movieGroups.putIfAbsent(movie, () => []).add(session);
    }

    final children = <Widget>[];
    final sortedMovies = movieGroups.keys.toList()..sort();

    for (int i = 0; i < sortedMovies.length; i++) {
      final movie = sortedMovies[i];
      final movieSessions = movieGroups[movie]!;

      children.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      movie.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse(movieSessions.first.bookingUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'BOOK',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.open_in_new,
                            size: 10,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: movieSessions
                  .map((s) => _SessionChip(session: s))
                  .toList(),
            ),
            if (i < sortedMovies.length - 1) const SizedBox(height: 16),
          ],
        ),
      );
    }
    return children;
  }
}

class _SessionChip extends StatelessWidget {
  final ShowSession session;

  const _SessionChip({required this.session});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color color;
    Color textColor = Colors.white;
    if (session.isAvailable) {
      color = Colors.green;
    } else if (session.isFilling) {
      color = Colors.orange;
    } else {
      color = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
    }

    return Tooltip(
      message:
          '${session.screenName}\n${session.statusText} (${session.availableSeats} seats)',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              session.showTime,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: textColor,
              ),
            ),
            if (session.format != null)
              Text(
                session.format!,
                style: TextStyle(
                  fontSize: 9,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
