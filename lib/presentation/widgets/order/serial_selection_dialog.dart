// ✅ presentation/widgets/order/serial_selection_dialog.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../../domain/entities/inventory_item.dart';
import '../../blocs/serial/serial_number_bloc.dart';
import '../../blocs/serial/serial_number_event.dart';
import '../../blocs/serial/serial_number_state.dart';

class SerialSelectionDialog extends StatefulWidget {
  final InventoryItem item;
  final int requiredQuantity;
  final List<String> preSelectedSerials;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;

  const SerialSelectionDialog({
    Key? key,
    required this.item,
    required this.requiredQuantity,
    this.preSelectedSerials = const [],
    this.rentalStartDate,
    this.rentalEndDate,
  }) : super(key: key);

  @override
  State<SerialSelectionDialog> createState() => _SerialSelectionDialogState();
}

class _SerialSelectionDialogState extends State<SerialSelectionDialog> {
  late Map<String, String> _selectedSerials;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _selectedSerials = {};

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.rentalStartDate != null && widget.rentalEndDate != null) {
        context.read<SerialNumberBloc>().add(
          LoadAvailableSerialsByDate(
            widget.item.id,
            startDate: widget.rentalStartDate,
            endDate: widget.rentalEndDate,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 750,
        height: 680,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            _buildHeader(theme, isDark),
            if (widget.rentalStartDate != null && widget.rentalEndDate != null)
              _buildDateRangeBanner(theme, isDark),
            _buildInfoBanner(theme, isDark),
            _buildSearchBar(theme, isDark),
            Expanded(child: _buildSerialList(theme, isDark)),
            _buildFooter(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'serial_selection.title'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'serial_selection.required'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '${widget.item.nameEn} (${'serial_selection.sku'.tr()} ${widget.item.sku})',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeBanner(ThemeData theme, bool isDark) {
    final dateFormat = intl.DateFormat('MMM dd, yyyy', context.locale.toString());
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.purple[900]!.withOpacity(0.3), Colors.purple[800]!.withOpacity(0.3)]
              : [Colors.purple[50]!, Colors.purple[100]!],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.purple[700]! : Colors.purple[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Colors.purple[isDark ? 300 : 700],
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: isDark ? Colors.purple[100] : Colors.purple[900],
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: '${'serial_selection.rental_period'.tr()} ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '${dateFormat.format(widget.rentalStartDate!)} - ${dateFormat.format(widget.rentalEndDate!)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue[900]?.withOpacity(0.3) : Colors.blue[50],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.blue[800]! : Colors.blue[100]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.primaryColor,
            size: 22,
          ),
          SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: isDark ? Colors.blue[100] : Colors.blue[900],
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'serial_selection.select_quantity'.tr(
                      namedArgs: {'quantity': widget.requiredQuantity.toString()},
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

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: TextField(
        onChanged: (v) => setState(() => _searchText = v),
        decoration: InputDecoration(
          hintText: 'serial_selection.search_hint'.tr(),
          prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => setState(() => _searchText = ''),
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildSerialList(ThemeData theme, bool isDark) {
    return BlocBuilder<SerialNumberBloc, SerialNumberState>(
      builder: (context, state) {
        if (state is SerialNumbersLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'serial_selection.checking_availability'.tr(),
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
              ],
            ),
          );
        }

        if (state is SerialNumbersError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  state.message,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is SerialNumbersLoaded) {
          var allSerials = state.serials.toList();
          final availabilityMap = state.availabilityMap;

          if (_searchText.isNotEmpty) {
            allSerials = allSerials
                .where((s) => s.serialNumber
                .toLowerCase()
                .contains(_searchText.toLowerCase()))
                .toList();
          }

          allSerials.sort((a, b) {
            if (availabilityMap != null) {
              final aAvailable =
                  availabilityMap[a.id]?.isAvailableForDates ?? false;
              final bAvailable =
                  availabilityMap[b.id]?.isAvailableForDates ?? false;

              if (aAvailable && !bAvailable) return -1;
              if (!aAvailable && bAvailable) return 1;
            }

            if (a.status == SerialStatus.available &&
                b.status != SerialStatus.available) return -1;
            if (b.status == SerialStatus.available &&
                a.status != SerialStatus.available) return 1;

            if (a.status == SerialStatus.rented &&
                b.status != SerialStatus.rented) return -1;
            if (b.status == SerialStatus.rented &&
                a.status != SerialStatus.rented) return 1;

            if (a.status == SerialStatus.damaged &&
                b.status != SerialStatus.damaged) return -1;
            if (b.status == SerialStatus.damaged &&
                a.status != SerialStatus.damaged) return 1;

            return 0;
          });

          if (allSerials.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: allSerials.length,
            itemBuilder: (_, i) => _buildSerialTile(
              allSerials[i],
              availabilityMap?[allSerials[i].id],
              theme,
              isDark,
            ),
          );
        }

        return SizedBox();
      },
    );
  }

  Widget _buildSerialTile(
      SerialNumber serial,
      SerialDateAvailability? availability,
      ThemeData theme,
      bool isDark,
      ) {
    final isSelected = _selectedSerials.containsKey(serial.id);
    final isAvailable = serial.status == SerialStatus.available;
    final isRented = serial.status == SerialStatus.rented;
    final isDamaged = serial.status == SerialStatus.damaged;

    final isAvailableForDates = availability?.isAvailableForDates ?? isAvailable;

    final canSelect = isAvailableForDates &&
        (isSelected || _selectedSerials.length < widget.requiredQuantity);

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDamaged
            ? Colors.red.withOpacity(0.05)
            : (!isAvailableForDates
            ? Colors.orange.withOpacity(0.05)
            : (isRented
            ? Colors.purple.withOpacity(0.05)
            : (isDark ? Colors.grey[850] : Colors.white))),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.green
              : (isDamaged
              ? Colors.red.withOpacity(0.3)
              : (!isAvailableForDates
              ? Colors.orange.withOpacity(0.3)
              : (isRented
              ? Colors.purple.withOpacity(0.3)
              : (isDark ? Colors.grey[700]! : Colors.grey[200]!)))),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        enabled: canSelect,
        onChanged: canSelect
            ? (selected) {
          setState(() {
            if (selected == true) {
              _selectedSerials[serial.id] = serial.serialNumber;
            } else {
              _selectedSerials.remove(serial.id);
            }
          });
        }
            : null,
        title: Row(
          children: [
            Expanded(
              child: Text(
                serial.serialNumber,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  fontSize: 15,
                  color: canSelect
                      ? theme.textTheme.bodyLarge?.color
                      : Colors.grey,
                ),
              ),
            ),
            if (!isAvailableForDates && !isDamaged) ...[
              Icon(Icons.event_busy, color: Colors.orange, size: 18),
              SizedBox(width: 6),
            ],
            if (isRented && isAvailableForDates) ...[
              Icon(Icons.calendar_today, color: Colors.green, size: 18),
              SizedBox(width: 6),
            ],
            if (isDamaged) ...[
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              SizedBox(width: 6),
            ],
            _buildStatusChip(serial.status, isAvailableForDates, theme),
          ],
        ),
        subtitle: _buildSubtitle(serial, availability, isDamaged, isAvailableForDates),
        secondary: CircleAvatar(
          backgroundColor: isSelected
              ? Colors.green
              : (canSelect
              ? theme.primaryColor.withOpacity(0.2)
              : Colors.grey[300]),
          child: Icon(
            isSelected
                ? Icons.check
                : (!isAvailableForDates
                ? Icons.event_busy
                : (isRented ? Icons.calendar_month : Icons.qr_code)),
            color: isSelected
                ? Colors.white
                : (canSelect ? theme.primaryColor : Colors.grey),
            size: 22,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget? _buildSubtitle(
      SerialNumber serial,
      SerialDateAvailability? availability,
      bool isDamaged,
      bool isAvailableForDates,
      ) {
    if (isDamaged) {
      return Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          'serial_selection.damaged_warning'.tr(),
          style: TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (!isAvailableForDates && availability != null) {
      final dateFormat =
      intl.DateFormat('MMM dd', context.locale.toString());
      String message = 'serial_selection.rented_during'.tr();

      if (availability.conflictStartDate != null &&
          availability.conflictEndDate != null) {
        message +=
        ' (${dateFormat.format(availability.conflictStartDate!)} - ${dateFormat.format(availability.conflictEndDate!)})';
      }

      return Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          message,
          style: TextStyle(
            color: Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (serial.status == SerialStatus.rented && isAvailableForDates) {
      return Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          'serial_selection.available_for_dates'.tr(),
          style: TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return null;
  }

  Widget _buildStatusChip(
      SerialStatus status,
      bool isAvailableForDates,
      ThemeData theme,
      ) {
    final statusColor =
    isAvailableForDates ? _getStatusColor(status) : Colors.orange;
    final statusText = isAvailableForDates
        ? _getStatusTranslation(status)
        : (status == SerialStatus.damaged
        ? 'serial_selection.damaged'.tr()
        : 'serial_selection.unavailable'.tr());

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    );
  }

  String _getStatusTranslation(SerialStatus status) {
    switch (status) {
      case SerialStatus.available:
        return 'serial_selection.available'.tr();
      case SerialStatus.reserved:
        return 'serial_selection.reserved'.tr();
      case SerialStatus.sold:
        return 'serial_selection.sold'.tr();
      case SerialStatus.rented:
        return 'serial_selection.rented'.tr();
      case SerialStatus.damaged:
        return 'serial_selection.damaged'.tr();
      case SerialStatus.returned:
        return 'serial_selection.returned'.tr();
      case SerialStatus.recalled:
        return 'serial_selection.recalled'.tr();
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 72,
            color: theme.disabledColor,
          ),
          SizedBox(height: 20),
          Text(
            _searchText.isEmpty
                ? 'serial_selection.no_serials_found'.tr()
                : 'serial_selection.no_search_results'.tr(
              namedArgs: {'query': _searchText},
            ),
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          if (_searchText.isNotEmpty) ...[
            SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _searchText = ''),
              child: Text('serial_selection.clear_search'.tr()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark) {
    final isValid = _selectedSerials.length == widget.requiredQuantity;
    final remaining = widget.requiredQuantity - _selectedSerials.length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
          if (_selectedSerials.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.green[900]?.withOpacity(0.2)
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.green[700]! : Colors.green[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'serial_selection.selected_serials'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.green[100] : Colors.green[900],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedSerials.values
                        .map(
                          (serialNumber) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: 14,
                              color: Colors.green[900],
                            ),
                            SizedBox(width: 6),
                            Text(
                              serialNumber,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Colors.green[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isValid
                        ? (isDark
                        ? Colors.green[900]?.withOpacity(0.3)
                        : Colors.green[100])
                        : (isDark
                        ? Colors.orange[900]?.withOpacity(0.3)
                        : Colors.orange[100]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isValid ? Icons.check_circle : Icons.warning_amber,
                        size: 20,
                        color: isValid
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                      SizedBox(width: 10),
                      Text(
                        isValid
                            ? 'serial_selection.ready_confirm'.tr(
                          namedArgs: {
                            'count': _selectedSerials.length.toString()
                          },
                        )
                            : 'serial_selection.select_more'.tr(
                          namedArgs: {
                            'remaining': remaining.toString(),
                            'plural': remaining != 1 ? 's' : ''
                          },
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isValid
                              ? Colors.green[900]
                              : Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child:
                Text('serial_selection.cancel'.tr(), style: TextStyle(fontSize: 15)),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: isValid
                    ? () {
                  final serialNumbers =
                  _selectedSerials.values.toList();
                  Navigator.of(context).pop(serialNumbers);
                }
                    : null,
                icon: Icon(Icons.check, size: 20),
                label: Text('serial_selection.confirm'.tr(),
                    style: TextStyle(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  disabledForegroundColor: Colors.grey[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SerialStatus status) {
    switch (status) {
      case SerialStatus.available:
        return Colors.green;
      case SerialStatus.reserved:
        return Colors.orange;
      case SerialStatus.sold:
        return Colors.blue;
      case SerialStatus.rented:
        return Colors.purple;
      case SerialStatus.damaged:
        return Colors.red;
      case SerialStatus.returned:
        return Colors.amber;
      case SerialStatus.recalled:
        return Colors.red[900]!;
    }
  }
}
