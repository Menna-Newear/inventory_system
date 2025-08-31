// presentation/widgets/inventory/inventory_search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/inventory/inventory_bloc.dart';

class InventorySearchBar extends StatefulWidget {
  @override
  State<InventorySearchBar> createState() => _InventorySearchBarState();
}

class _InventorySearchBarState extends State<InventorySearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryLoaded && state.searchQuery == null) {
          _searchController.clear();
        }
      },
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          context.read<InventoryBloc>().add(SearchInventoryItems(query));
        },
        decoration: InputDecoration(
          hintText: 'Search by name, SKU, or description...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<InventoryBloc>().add(SearchInventoryItems(''));
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
