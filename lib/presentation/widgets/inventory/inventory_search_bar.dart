// ✅ presentation/widgets/inventory/inventory_search_bar.dart (FULLY LOCALIZED!)
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/inventory/inventory_bloc.dart';

class InventorySearchBar extends StatefulWidget {
  @override
  State<InventorySearchBar> createState() => _InventorySearchBarState();
}

class _InventorySearchBarState extends State<InventorySearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryLoaded && state.searchQuery == null) {
          _searchController.clear();
          setState(() => _isSearching = false);
        }
      },
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          // Cancel previous timer
          _debounceTimer?.cancel();

          if (query.isEmpty) {
            // Clear search immediately
            setState(() => _isSearching = false);
            context.read<InventoryBloc>().add(SearchInventoryItems(''));
          } else {
            // Show loading indicator
            setState(() => _isSearching = true);

            // Wait 500ms before searching
            _debounceTimer = Timer(Duration(milliseconds: 500), () {
              context.read<InventoryBloc>().add(SearchInventoryItems(query));
              setState(() => _isSearching = false);
            });
          }
        },
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'inventory_search.hint'.tr(),
          hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.iconTheme.color,
          ),
          suffixIcon: _buildSuffixIcon(theme),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.primaryColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildSuffixIcon(ThemeData theme) {
    if (_searchController.text.isEmpty) {
      return SizedBox.shrink();
    }

    if (_isSearching) {
      // Show loading indicator when typing
      return Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.brightness == Brightness.dark
                  ? Colors.blue[400]!
                  : Colors.blue[600]!,
            ),
          ),
        ),
      );
    } else {
      // Show clear button when not searching
      return IconButton(
        icon: Icon(
          Icons.clear,
          color: theme.iconTheme.color,
        ),
        onPressed: () {
          _searchController.clear();
          _debounceTimer?.cancel();
          setState(() => _isSearching = false);
          context.read<InventoryBloc>().add(SearchInventoryItems(''));
        },
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
