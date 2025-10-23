// ✅ presentation/widgets/order/order_search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';

class OrderSearchBar extends StatefulWidget {
  @override
  State<OrderSearchBar> createState() => _OrderSearchBarState();
}

class _OrderSearchBarState extends State<OrderSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderLoaded) {
          setState(() => _isSearching = false);
          if (state.searchQuery == null) {
            _searchController.clear();
          }
        } else if (state is OrderLoading) {
          setState(() => _isSearching = true);
        }
      },
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          setState(() => _isSearching = query.isNotEmpty);
          context.read<OrderBloc>().add(SearchOrdersEvent(query));
        },
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search orders by number, customer, or email...',
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
    if (_isSearching && _searchController.text.isNotEmpty) {
      // Show loading indicator when searching
      return Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
        ),
      );
    } else if (_searchController.text.isNotEmpty) {
      // Show clear button when search is complete
      return IconButton(
        icon: Icon(
          Icons.clear,
          color: theme.iconTheme.color,
        ),
        onPressed: () {
          _searchController.clear();
          setState(() => _isSearching = false);
          context.read<OrderBloc>().add(SearchOrdersEvent(''));
        },
      );
    }
    return SizedBox.shrink();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
