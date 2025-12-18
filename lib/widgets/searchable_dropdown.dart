import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final String hintText;
  final IconData? prefixIcon;
  final String? searchHint;

  const SearchableDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.hintText,
    this.prefixIcon,
    this.searchHint,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () async {
        final result = await showModalBottomSheet<T>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => _SearchSheet<T>(
            items: items,
            itemLabel: itemLabel,
            title: hintText,
            searchHint: searchHint,
            selectedValue: value,
          ),
        );

        // If result is null, it might mean dismissed without selection,
        // unlike DropdownButton explicitly selecting null.
        // We only trigger onChanged if a selection was actually made (handled in _SearchSheet).
        // However, if we want to allow clearing, we'd need a clear button.
        // For now, let's assume if they pick something, we update.
        if (result != null) {
          onChanged(result);
        } else if (value != null && items.contains(null)) {
          // Handle explicit null selection if 'All' option exists as null
          // But T is usually non-nullable in the list, except 'All Theatres' case
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          border: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(
              Radius.circular(4),
            ), // Standard Material default
          ),
          hintText: hintText,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value != null ? itemLabel(value as T) : hintText,
          style: value != null
              ? textTheme.bodyLarge
              : textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SearchSheet<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemLabel;
  final String title;
  final String? searchHint;
  final T? selectedValue;

  const _SearchSheet({
    required this.items,
    required this.itemLabel,
    required this.title,
    this.searchHint,
    this.selectedValue,
  });

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredItems = widget.items.where((item) {
          if (item == null)
            return false; // Skip null items in search (like "All Theatres")
          return widget.itemLabel(item).toLowerCase().contains(lowercaseQuery);
        }).toList();

        // Always keep the "All/None" option (null value) if it exists in the original list
        // and check if it matches query or just keep it at top?
        // Usually "All" is selected by just clearing search?
        // Let's simpler: If original list has null (All), and query is empty, it shows.
        // If query is not empty, usually we don't show "All" unless "All" matches the text.

        if (widget.items.contains(null) && query.isEmpty) {
          if (!_filteredItems.contains(null)) {
            _filteredItems.insert(0, null as T);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: widget.searchHint ?? 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _filterItems,
                ),
              ),

              const Divider(),

              // List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _filteredItems.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final label = item == null
                        ? 'All Theatres'
                        : widget.itemLabel(item);
                    final isSelected = widget.selectedValue == item;

                    // Specific check for Movie type to show extra info if possible
                    // Since T is generic, we can't easily access properties unless we check type
                    // But we can stick to simple label for now as requested.

                    return ListTile(
                      title: Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: colorScheme.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(context, item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
