// presentation/widgets/inventory/serial_number_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/inventory_item.dart';
import '../../viewmodels/serial_number_viewmodel.dart';

class SerialNumberDialog extends StatefulWidget {
  final InventoryItem item;
  final VoidCallback? onUpdated;

  const SerialNumberDialog({
    Key? key,
    required this.item,
    this.onUpdated,
  }) : super(key: key);

  @override
  State<SerialNumberDialog> createState() => _SerialNumberDialogState();
}

class _SerialNumberDialogState extends State<SerialNumberDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _quantityController = TextEditingController();
  final _manualSerialController = TextEditingController();
  final List<String> _selectedSerials = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        child: Column(
          children: [
            // ✅ HEADER
            Container(
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
                        Text(
                          'Serial Number Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.item.nameEn} (SKU: ${widget.item.sku})',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ✅ TABS
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: Icon(Icons.list), text: 'View Serials'),
                Tab(icon: Icon(Icons.add), text: 'Add Serials'),
                Tab(icon: Icon(Icons.edit), text: 'Manage'),
              ],
            ),

            // ✅ TAB CONTENT
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

            // ✅ FOOTER
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  _buildStatusSummary(),
                  Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ VIEW SERIALS TAB
  Widget _buildViewTab() {
    return Consumer<SerialNumberViewModel>(
      builder: (context, viewModel, child) {
        final serials = widget.item.serialNumbers;

        if (serials.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No serial numbers found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Add serial numbers using the "Add Serials" tab',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Filter/Search bar
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search serial numbers...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  DropdownButton<SerialStatus?>(
                    hint: Text('Filter by Status'),
                    items: [
                      DropdownMenuItem(value: null, child: Text('All')),
                      ...SerialStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      )),
                    ],
                    onChanged: (value) {
                      // Implement filtering logic
                    },
                  ),
                ],
              ),
            ),

            // Serial numbers list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: serials.length,
                itemBuilder: (context, index) {
                  final serial = serials[index];
                  return _buildSerialCard(serial);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ ADD SERIALS TAB
  Widget _buildAddTab() {
    return Consumer<SerialNumberViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ AUTO GENERATE SECTION
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Generate Serial Numbers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity to Generate',
                                hintText: 'Enter number of serials',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: viewModel.isLoading ? null : _generateSerials,
                            icon: Icon(Icons.auto_awesome),
                            label: Text('Generate'),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                      _buildSerialPreview(),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // ✅ MANUAL ADD SECTION
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Manual Serial Number',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualSerialController,
                              decoration: InputDecoration(
                                labelText: 'Serial Number',
                                hintText: widget.item.serialNumberPrefix != null
                                    ? '${widget.item.serialNumberPrefix}...'
                                    : 'Enter serial number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: viewModel.isLoading ? null : _addManualSerial,
                            icon: Icon(Icons.add),
                            label: Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (viewModel.isLoading) ...[
                SizedBox(height: 16),
                Center(child: CircularProgressIndicator()),
              ],

              if (viewModel.errorMessage != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viewModel.errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ✅ MANAGE TAB
  Widget _buildManageTab() {
    return Consumer<SerialNumberViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            // Bulk actions toolbar
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Text('Selected: ${_selectedSerials.length}'),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _selectedSerials.isEmpty ? null : () => _bulkUpdateStatus(SerialStatus.sold),
                    icon: Icon(Icons.shopping_cart),
                    label: Text('Mark Sold'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedSerials.isEmpty ? null : () => _bulkUpdateStatus(SerialStatus.damaged),
                    icon: Icon(Icons.broken_image),
                    label: Text('Mark Damaged'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedSerials.isEmpty ? null : () => _bulkUpdateStatus(SerialStatus.available),
                    icon: Icon(Icons.refresh),
                    label: Text('Reset to Available'),
                  ),
                ],
              ),
            ),

            // Serial list with checkboxes
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: widget.item.serialNumbers.length,
                itemBuilder: (context, index) {
                  final serial = widget.item.serialNumbers[index];
                  return _buildManageableSerialCard(serial);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ HELPER WIDGETS
  Widget _buildSerialCard(SerialNumber serial) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(serial.status),
          child: Icon(Icons.qr_code, color: Colors.white, size: 20),
        ),
        title: Text(
          serial.serialNumber,
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${serial.status.displayName}'),
            if (serial.notes != null && serial.notes!.isNotEmpty)
              Text('Notes: ${serial.notes}', style: TextStyle(fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            ...SerialStatus.values.map((status) => PopupMenuItem(
              value: status,
              child: Text('Mark as ${status.displayName}'),
            )),
          ],
          onSelected: (SerialStatus status) {
            context.read<SerialNumberViewModel>().updateSerialStatus(serial.id, status);
          },
        ),
      ),
    );
  }

  Widget _buildManageableSerialCard(SerialNumber serial) {
    final isSelected = _selectedSerials.contains(serial.id);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue[50] : null,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? selected) {
          setState(() {
            if (selected == true) {
              _selectedSerials.add(serial.id);
            } else {
              _selectedSerials.remove(serial.id);
            }
          });
        },
        secondary: CircleAvatar(
          backgroundColor: _getStatusColor(serial.status),
          child: Icon(Icons.qr_code, color: Colors.white, size: 20),
        ),
        title: Text(
          serial.serialNumber,
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
        subtitle: Text('Status: ${serial.status.displayName}'),
      ),
    );
  }

  Widget _buildStatusSummary() {
    final serials = widget.item.serialNumbers;
    final available = serials.where((s) => s.status == SerialStatus.available).length;
    final sold = serials.where((s) => s.status == SerialStatus.sold).length;
    final damaged = serials.where((s) => s.status == SerialStatus.damaged).length;

    return Row(
      children: [
        _buildStatusChip('Available', available, Colors.green),
        SizedBox(width: 8),
        _buildStatusChip('Sold', sold, Colors.blue),
        SizedBox(width: 8),
        _buildStatusChip('Damaged', damaged, Colors.red),
        SizedBox(width: 8),
        _buildStatusChip('Total', serials.length, Colors.grey),
      ],
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label: $count'),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildSerialPreview() {
    if (widget.item.serialNumberPrefix == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview Format:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(
            'Next serial: ${widget.item.generateNextSerialNumber()}',
            style: TextStyle(fontFamily: 'monospace', color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  // ✅ HELPER METHODS
  Color _getStatusColor(SerialStatus status) {
    switch (status) {
      case SerialStatus.available: return Colors.green;
      case SerialStatus.reserved: return Colors.orange;
      case SerialStatus.sold: return Colors.blue;
      case SerialStatus.damaged: return Colors.red;
      case SerialStatus.returned: return Colors.purple;
      case SerialStatus.recalled: return Colors.red[900]!;
    }
  }

  void _generateSerials() async {
    final quantityText = _quantityController.text.trim();
    if (quantityText.isEmpty) {
      _showError('Please enter quantity');
      return;
    }

    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      _showError('Please enter a valid quantity');
      return;
    }

    try {
      final viewModel = context.read<SerialNumberViewModel>();
      final newSerials = viewModel.generateSerialNumbers(widget.item, quantity);
      final success = await viewModel.addSerialNumbers(widget.item.id, newSerials);

      if (success) {
        _quantityController.clear();
        widget.onUpdated?.call();
        _showSuccess('Generated $quantity serial numbers successfully');
      }
    } catch (e) {
      _showError('Failed to generate serials: $e');
    }
  }

  void _addManualSerial() async {
    final serialNumber = _manualSerialController.text.trim();
    if (serialNumber.isEmpty) {
      _showError('Please enter a serial number');
      return;
    }

    final viewModel = context.read<SerialNumberViewModel>();

    if (!viewModel.validateSerialNumber(serialNumber, widget.item)) {
      _showError('Invalid serial number format');
      return;
    }

    if (viewModel.isDuplicateSerial(serialNumber, widget.item)) {
      _showError('Serial number already exists');
      return;
    }

    final newSerial = SerialNumber(
      id: '',
      itemId: widget.item.id,
      serialNumber: serialNumber,
      status: SerialStatus.available,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await viewModel.addSerialNumbers(widget.item.id, [newSerial]);
    if (success) {
      _manualSerialController.clear();
      widget.onUpdated?.call();
      _showSuccess('Added serial number successfully');
    }
  }

  void _bulkUpdateStatus(SerialStatus status) async {
    final viewModel = context.read<SerialNumberViewModel>();
    final success = await viewModel.bulkUpdateStatus(_selectedSerials, status);

    if (success) {
      setState(() => _selectedSerials.clear());
      widget.onUpdated?.call();
      _showSuccess('Updated serial statuses successfully');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _manualSerialController.dispose();
    super.dispose();
  }
}
