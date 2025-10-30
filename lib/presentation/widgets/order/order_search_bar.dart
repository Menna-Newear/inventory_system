// ✅ presentation/widgets/order/order_search_bar.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';

class OrderSearchBar extends StatefulWidget {
  final double? width;
  final Function(String)? onSearchChanged;

  const OrderSearchBar({
    Key? key,
    this.width,
    this.onSearchChanged,
  }) : super(key: key);

  @override
  State<OrderSearchBar> createState() => _OrderSearchBarState();
}

class _OrderSearchBarState extends State<OrderSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    widget.onSearchChanged?.call(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderLoaded) {
          setState(() => _isSearching = false);
          if (state.searchQuery == null || state.searchQuery!.isEmpty) {
            _searchController.clear();
          }
        } else if (state is OrderLoading) {
          setState(() => _isSearching = true);
        }
      },
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (_focusNode.hasFocus)
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (query) {
            setState(() => _isSearching = query.isNotEmpty);
            context.read<OrderBloc>().add(SearchOrdersEvent(query));
          },
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'order_search.hint'.tr(),
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            suffixIcon: _buildSuffixIcon(theme, isDark),
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
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }

  Widget _buildSuffixIcon(ThemeData theme, bool isDark) {
    if (_isSearching && _searchController.text.isNotEmpty) {
      // Show loading indicator when searching
      return Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
        ),
      );
    } else if (_searchController.text.isNotEmpty) {
      // Show clear button when search is complete
      return Tooltip(
        message: 'order_search.clear_search'.tr(),
        child: IconButton(
          icon: Icon(
            Icons.clear,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          onPressed: _clearSearch,
          splashRadius: 20,
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      );
    }
    return SizedBox.shrink();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _isSearching = false);
    context.read<OrderBloc>().add(SearchOrdersEvent(''));
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
