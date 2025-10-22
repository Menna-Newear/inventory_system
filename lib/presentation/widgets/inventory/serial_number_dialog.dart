// lib/presentation/widgets/inventory/serial_number_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../blocs/serial/serial_number_bloc.dart';
import '../../blocs/serial/serial_number_event.dart';
import '../../blocs/serial/serial_number_state.dart';

class SerialNumberDialog extends StatefulWidget {
  final InventoryItem item;
  final VoidCallback? onUpdated;

  const SerialNumberDialog({Key? key, required this.item, this.onUpdated}) : super(key: key);

  @override
  State<SerialNumberDialog> createState() => _SerialNumberDialogState();
}

class _SerialNumberDialogState extends State<SerialNumberDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _quantityController = TextEditingController();
  final _manualSerialController = TextEditingController();
  final List<String> _selectedSerials = [];
  String _searchText = '';
  SerialStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reloadSerials();
  }

  void _reloadSerials() {
    context.read<SerialNumberBloc>().add(LoadSerialNumbers(widget.item.id));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        child: Column(
          children: [
            _buildHeader(),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: Icon(Icons.list), text: 'View Serials'),
                Tab(icon: Icon(Icons.add), text: 'Add Serials'),
                Tab(icon: Icon(Icons.edit), text: 'Manage'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildViewTab(),
                  _buildAddTab(),
                  _buildManageTab(),
                ],
              ),
            ),
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
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Serial Number Management', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${widget.item.nameEn} (SKU: ${widget.item.sku})', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          IconButton(icon: Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _buildViewTab() {
    return BlocBuilder<SerialNumberBloc, SerialNumberState>(
      builder: (context, state) {
        if (state is SerialNumbersLoading) return Center(child: CircularProgressIndicator());
        if (state is SerialNumbersError) return Center(child: Text(state.message, style: TextStyle(color: Colors.red)));
        if (state is SerialNumbersLoaded) {
          var serials = state.serials;
          if (_searchText.isNotEmpty)
            serials = serials.where((s) => s.serialNumber.toLowerCase().contains(_searchText.toLowerCase())).toList();
          if (_filterStatus != null)
            serials = serials.where((s) => s.status == _filterStatus).toList();

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchText = v),
                        decoration: InputDecoration(hintText: 'Search serial numbers...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                      ),
                    ),
                    SizedBox(width: 16),
                    DropdownButton<SerialStatus?>(
                      value: _filterStatus,
                      hint: Text('Filter by Status'),
                      items: [
                        DropdownMenuItem(value: null, child: Text('All')),
                        ...SerialStatus.values.map((status) => DropdownMenuItem(value: status, child: Text(status.displayName))),
                      ],
                      onChanged: (value) => setState(() => _filterStatus = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: serials.isEmpty ? Center(child: Text('No serial numbers found.')) : ListView.builder(itemCount: serials.length, itemBuilder: (_, i) => _buildSerialCard(serials[i])),
              ),
            ],
          );
        }
        return SizedBox();
      },
    );
  }

  Widget _buildAddTab() {
    return BlocConsumer<SerialNumberBloc, SerialNumberState>(
      listener: (context, state) {
        if (state is SerialNumbersError) _showError(state.message);
        if (state is SerialNumbersLoaded && widget.onUpdated != null) widget.onUpdated!();
      },
      builder: (context, state) {
        final isLoading = state is SerialNumbersLoading;
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto Generate Serial Numbers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: 'Quantity to Generate', hintText: 'Enter number of serials', border: OutlineInputBorder()),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton.icon(onPressed: isLoading ? null : _generateSerials, icon: Icon(Icons.auto_awesome), label: Text('Generate')),
                        ],
                      ),
                      SizedBox(height: 16), _buildSerialPreview(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Manual Serial Number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualSerialController,
                              decoration: InputDecoration(labelText: 'Serial Number', hintText: widget.item.serialNumberPrefix ?? 'Enter serial number', border: OutlineInputBorder()),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton.icon(onPressed: isLoading ? null : _addManualSerial, icon: Icon(Icons.add), label: Text('Add')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManageTab() {
    return BlocBuilder<SerialNumberBloc, SerialNumberState>(
        builder: (context, state) {
          if (state is SerialNumbersLoaded) {
            final serials = state.serials;
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Row(
                    children: [
                      Text('Selected: ${_selectedSerials.length}'),
                      SizedBox(width: 16),
                      ElevatedButton.icon(onPressed: _selectedSerials.isEmpty ? null : () => _bulkUpdateStatus(SerialStatus.sold), icon: Icon(Icons.shopping_cart), label: Text('Mark Sold')),
                      SizedBox(width: 8),
                      ElevatedButton.icon(onPressed: _selectedSerials.isEmpty ? null : () => _bulkUpdateStatus(SerialStatus.damaged), icon: Icon(Icons.broken_image), label: Text('Mark Damaged')),
                      SizedBox(width: 8),
                      ElevatedButton.icon(onPressed: _selectedSerials.isEmpty ? null : () => _bulkUpdateStatus(SerialStatus.available), icon: Icon(Icons.refresh), label: Text('Reset to Available')),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: serials.map((serial) {
                      final isSelected = _selectedSerials.contains(serial.id);
                      return CheckboxListTile(
                        value: isSelected,
                        secondary: CircleAvatar(backgroundColor: _getStatusColor(serial.status), child: Icon(Icons.qr_code, color: Colors.white, size: 20)),
                        title: Text(serial.serialNumber, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        subtitle: Text('Status: ${serial.status.displayName}'),
                        onChanged: (selected) {
                          setState(() {
                            if (selected ?? false) {
                              _selectedSerials.add(serial.id);
                            } else {
                              _selectedSerials.remove(serial.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }
          if (state is SerialNumbersError) return Center(child: Text(state.message, style: TextStyle(color: Colors.red)));
          return Center(child: CircularProgressIndicator());
        }
    );
  }

  Widget _buildSerialCard(SerialNumber serial) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: _getStatusColor(serial.status), child: Icon(Icons.qr_code, color: Colors.white, size: 20)),
        title: Text(serial.serialNumber, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        subtitle: Text('Status: ${serial.status.displayName}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [...SerialStatus.values.map((status) => PopupMenuItem(value: status, child: Text('Mark as ${status.displayName}')))],
          onSelected: (SerialStatus status) => context.read<SerialNumberBloc>().add(BulkUpdateSerialStatus([serial.id], status)),
        ),
      ),
    );
  }

  Widget _buildSerialPreview() {
    if (widget.item.serialNumberPrefix == null) return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview Format:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Next serial: ${widget.item.generateNextSerialNumber?.call() ?? ''}', style: TextStyle(fontFamily: 'monospace', color: Colors.blue[700])),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final serials = widget.item.serialNumbers;
    final available = serials.where((s) => s.status == SerialStatus.available).length;
    final sold = serials.where((s) => s.status == SerialStatus.sold).length;
    final damaged = serials.where((s) => s.status == SerialStatus.damaged).length;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.vertical(bottom: Radius.circular(8))),
      child: Row(
        children: [
          _buildStatusChip('Available', available, Colors.green),
          SizedBox(width: 8),
          _buildStatusChip('Sold', sold, Colors.blue),
          SizedBox(width: 8),
          _buildStatusChip('Damaged', damaged, Colors.red),
          SizedBox(width: 8),
          _buildStatusChip('Total', serials.length, Colors.grey),
          Spacer(),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Close')),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Chip(label: Text('$label: $count'), backgroundColor: color.withOpacity(0.1), side: BorderSide(color: color));
  }

  Color _getStatusColor(SerialStatus status) {
    switch (status) {
      case SerialStatus.available: return Colors.green;
      case SerialStatus.reserved: return Colors.orange;
      case SerialStatus.sold: return Colors.blue;
      case SerialStatus.damaged: return Colors.red;
      case SerialStatus.rented: return Colors.purple;
      case SerialStatus.returned: return Colors.amber;
      case SerialStatus.recalled: return Colors.red[900]!;
    }
  }

  void _generateSerials() {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showError('Please enter a valid quantity');
      return;
    }
    final serials = List.generate(quantity, (i) {
      final prefix = widget.item.serialNumberPrefix ?? '';
      final numStr = (i + 1).toString().padLeft(widget.item.serialNumberLength ?? 4, '0');
      return SerialNumber(id: '', itemId: widget.item.id, serialNumber: '$prefix$numStr', status: SerialStatus.available, createdAt: DateTime.now(), updatedAt: DateTime.now());
    });
    context.read<SerialNumberBloc>().add(AddSerialNumbers(widget.item.id, serials));
    _quantityController.clear();
  }

  void _addManualSerial() {
    final serialText = _manualSerialController.text.trim();
    if (serialText.isEmpty) {
      _showError('Please enter a serial number');
      return;
    }
    final serial = SerialNumber(id: '', itemId: widget.item.id, serialNumber: serialText, status: SerialStatus.available, createdAt: DateTime.now(), updatedAt: DateTime.now());
    context.read<SerialNumberBloc>().add(AddSerialNumbers(widget.item.id, [serial]));
    _manualSerialController.clear();
  }

  void _bulkUpdateStatus(SerialStatus status) {
    context.read<SerialNumberBloc>().add(BulkUpdateSerialStatus(_selectedSerials, status));
    setState(() => _selectedSerials.clear());
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _manualSerialController.dispose();
    super.dispose();
  }
}
