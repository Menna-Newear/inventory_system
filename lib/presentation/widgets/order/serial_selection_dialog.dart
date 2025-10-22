// presentation/widgets/order/serial_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../blocs/serial/serial_number_bloc.dart';
import '../../blocs/serial/serial_number_event.dart';
import '../../blocs/serial/serial_number_state.dart';

class SerialSelectionDialog extends StatefulWidget {
  final InventoryItem item;
  final int requiredQuantity;
  final List<String> preSelectedSerials;

  const SerialSelectionDialog({
    Key? key,
    required this.item,
    required this.requiredQuantity,
    this.preSelectedSerials = const [],
  }) : super(key: key);

  @override
  State<SerialSelectionDialog> createState() => _SerialSelectionDialogState();
}

class _SerialSelectionDialogState extends State<SerialSelectionDialog> {
  late Map<String, String> _selectedSerials; // Key: serial ID, Value: serial number string
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _selectedSerials = {};
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 650,
        height: 550,
        child: Column(
          children: [
            _buildHeader(),
            _buildInfoBanner(),
            _buildSearchBar(),
            Expanded(child: _buildSerialList()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Select Serial Numbers',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    // ✅ REQUIRED badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'REQUIRED',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${widget.item.nameEn} (SKU: ${widget.item.sku})',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue[50],
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please select exactly ${widget.requiredQuantity} serial number(s) for this order',
              style: TextStyle(color: Colors.blue[900], fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        onChanged: (v) => setState(() => _searchText = v),
        decoration: InputDecoration(
          hintText: 'Search by serial number...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => setState(() => _searchText = ''),
          )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildSerialList() {
    return BlocBuilder<SerialNumberBloc, SerialNumberState>(
      builder: (context, state) {
        if (state is SerialNumbersLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading available serial numbers...'),
              ],
            ),
          );
        }
        if (state is SerialNumbersError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],
            ),
          );
        }
        if (state is SerialNumbersLoaded) {
          // ✅ Filter: only available serials + pre-selected ones
          var availableSerials = state.serials
              .where((s) => s.status == SerialStatus.available || _selectedSerials.containsKey(s.id))
              .toList();

          if (_searchText.isNotEmpty) {
            availableSerials = availableSerials
                .where((s) => s.serialNumber.toLowerCase().contains(_searchText.toLowerCase()))
                .toList();
          }

          if (availableSerials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    _searchText.isEmpty ? 'No available serial numbers found' : 'No results for "$_searchText"',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  if (_searchText.isNotEmpty) ...[
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _searchText = ''),
                      child: Text('Clear search'),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: availableSerials.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (_, i) => _buildSerialCheckbox(availableSerials[i]),
          );
        }
        return SizedBox();
      },
    );
  }

  Widget _buildSerialCheckbox(SerialNumber serial) {
    // ✅ CHANGED: Check if serial ID is in the map
    final isSelected = _selectedSerials.containsKey(serial.id);
    final canToggle = isSelected || _selectedSerials.length < widget.requiredQuantity;

    return CheckboxListTile(
      value: isSelected,
      enabled: canToggle,
      onChanged: canToggle
          ? (selected) {
        setState(() {
          if (selected == true) {
            // ✅ CHANGED: Store both ID and serial number string
            _selectedSerials[serial.id] = serial.serialNumber;
            print('✅ Selected serial: ${serial.serialNumber} (ID: ${serial.id})');
          } else {
            _selectedSerials.remove(serial.id);
            print('❌ Deselected serial: ${serial.serialNumber}');
          }
        });
      }
          : null,
      title: Text(
        serial.serialNumber,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontFamily: 'monospace',
          fontSize: 14,
          color: canToggle ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(serial.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _getStatusColor(serial.status)),
            ),
            child: Text(
              serial.status.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(serial.status),
              ),
            ),
          ),
        ],
      ),
      secondary: CircleAvatar(
        backgroundColor: isSelected ? Colors.green : (canToggle ? Colors.grey[300] : Colors.grey[200]),
        child: Icon(
          isSelected ? Icons.check : Icons.qr_code,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final isValid = _selectedSerials.length == widget.requiredQuantity;
    final remaining = widget.requiredQuantity - _selectedSerials.length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // ✅ Show selected serial numbers preview
          if (_selectedSerials.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Serial Numbers:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedSerials.values.map((serialNumber) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Text(
                        serialNumber,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.green[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: Chip(
                  label: Text(
                    isValid
                        ? 'Ready to confirm (${_selectedSerials.length} selected)'
                        : 'Select $remaining more serial${remaining != 1 ? 's' : ''}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  backgroundColor: isValid ? Colors.green[100] : Colors.orange[100],
                  avatar: Icon(
                    isValid ? Icons.check_circle : Icons.warning,
                    size: 20,
                    color: isValid ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Cancel', style: TextStyle(fontSize: 14)),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: isValid
                    ? () {
                  // ✅ CHANGED: Return list of serial number STRINGS (not IDs)
                  final serialNumbers = _selectedSerials.values.toList();
                  print('✅ Confirming selection of ${serialNumbers.length} serials: $serialNumbers');
                  Navigator.of(context).pop(serialNumbers);
                }
                    : null,
                icon: Icon(Icons.check, size: 18),
                label: Text('Confirm Selection', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
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
