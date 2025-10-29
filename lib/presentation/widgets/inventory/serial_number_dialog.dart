// ✅ lib/presentation/widgets/inventory/serial_number_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../blocs/serial/serial_number_bloc.dart';
import '../../blocs/serial/serial_number_event.dart';
import '../../blocs/serial/serial_number_state.dart';

class SerialNumberDialog extends StatefulWidget {
  final InventoryItem item;
  final VoidCallback? onUpdated;
  final bool canManage;

  const SerialNumberDialog({
    Key? key,
    required this.item,
    this.onUpdated,
    this.canManage = true,
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
  String _searchText = '';
  SerialStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.canManage ? 3 : 1, // ✅ 1 tab for viewers, 3 for managers
      vsync: this,
    );    _reloadSerials();
  }

  void _reloadSerials() {
    context.read<SerialNumberBloc>().add(LoadSerialNumbers(widget.item.id));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        child: Column(
          children: [
            _buildHeader(),
            TabBar(
              controller: _tabController,
              tabs: widget.canManage
                  ? [
                      Tab(icon: Icon(Icons.list), text: 'View Serials'),
                      Tab(
                        icon: Icon(Icons.add_circle_outline),
                        text: 'Generate',
                      ),
                      Tab(icon: Icon(Icons.edit_note), text: 'Manage'),
                    ]
                  : [Tab(icon: Icon(Icons.list), text: 'View Serials')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: widget.canManage
                    ? [
                  _buildViewTab(),
                  _buildAddTab(),
                  _buildManageTab(),
                ]
                    : [
                  _buildViewTab(),
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.canManage ? Theme.of(context).primaryColor : Colors.grey,
            widget.canManage
                ? Theme.of(context).primaryColor.withOpacity(0.8)
                : Colors.grey.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.qr_code_2, color: Colors.white, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.canManage
                          ? 'Serial Number Management'
                          : 'Serial Numbers (View Only)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!widget.canManage) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'READ ONLY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${widget.item.nameEn} • SKU: ${widget.item.sku}',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab() {
    return BlocBuilder<SerialNumberBloc, SerialNumberState>(
      builder: (context, state) {
        if (state is SerialNumbersLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is SerialNumbersError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: Colors.red)),
              ],
            ),
          );
        }
        if (state is SerialNumbersLoaded) {
          var serials = state.serials;
          if (_searchText.isNotEmpty) {
            serials = serials
                .where(
                  (s) => s.serialNumber.toLowerCase().contains(
                    _searchText.toLowerCase(),
                  ),
                )
                .toList();
          }
          if (_filterStatus != null) {
            serials = serials.where((s) => s.status == _filterStatus).toList();
          }

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchText = v),
                        decoration: InputDecoration(
                          hintText: 'Search serial numbers...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<SerialStatus?>(
                        value: _filterStatus,
                        hint: Text('Filter by Status'),
                        underline: SizedBox(),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All Statuses'),
                          ),
                          ...SerialStatus.values.map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(status.displayName),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _filterStatus = value),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: serials.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No serial numbers found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Generate serial numbers in the "Generate" tab',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: serials.length,
                        itemBuilder: (_, i) => _buildSerialCard(serials[i]),
                      ),
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
        if (state is SerialNumbersError) {
          _showError(state.message);
        }
        if (state is SerialNumbersLoaded) {
          _showSuccess('Serial numbers generated successfully!');
          if (widget.onUpdated != null) widget.onUpdated!();
        }
      },
      builder: (context, state) {
        final isLoading = state is SerialNumbersLoading;

        // ✅ Get current count from BLoC state
        int currentSerialCount = 0;
        if (state is SerialNumbersLoaded) {
          currentSerialCount = state.serials.length;
        } else {
          currentSerialCount = widget.item.serialNumbers.length;
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.blue,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Auto-Generate Serial Numbers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Serial Number Format',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'SKU-000001, SKU-000002, etc.',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                color: Colors.blue[800],
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Current Stock: ${widget.item.stockQuantity} units',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[900],
                              ),
                            ),
                            Text(
                              'Existing Serials: $currentSerialCount',
                              style: TextStyle(color: Colors.blue[800]),
                            ),
                            if (currentSerialCount < widget.item.stockQuantity)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Need ${widget.item.stockQuantity - currentSerialCount} more serial numbers',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity to Generate',
                                hintText: 'Enter number of serials',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.numbers),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: isLoading ? null : _generateSerials,
                            icon: Icon(Icons.auto_awesome),
                            label: Text('Generate'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildSerialPreview(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit, color: Colors.green, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Add Manual Serial Number',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualSerialController,
                              decoration: InputDecoration(
                                labelText: 'Serial Number',
                                hintText: '${widget.item.sku}-XXXXXX',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.qr_code),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: isLoading ? null : _addManualSerial,
                            icon: Icon(Icons.add),
                            label: Text('Add'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
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
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Selected: ${_selectedSerials.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _selectedSerials.isEmpty
                          ? null
                          : () => _bulkUpdateStatus(SerialStatus.sold),
                      icon: Icon(Icons.shopping_cart, size: 18),
                      label: Text('Mark Sold'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectedSerials.isEmpty
                          ? null
                          : () => _bulkUpdateStatus(SerialStatus.damaged),
                      icon: Icon(Icons.broken_image, size: 18),
                      label: Text('Mark Damaged'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectedSerials.isEmpty
                          ? null
                          : () => _bulkUpdateStatus(SerialStatus.available),
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: serials.map((serial) {
                    final isSelected = _selectedSerials.contains(serial.id);
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: isSelected,
                        secondary: CircleAvatar(
                          backgroundColor: _getStatusColor(serial.status),
                          child: Icon(
                            Icons.qr_code,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          serial.serialNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 16,
                          ),
                        ),
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
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }
        if (state is SerialNumbersError) {
          return Center(
            child: Text(state.message, style: TextStyle(color: Colors.red)),
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(serial.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(serial.status)),
              ),
              child: Text(
                serial.status.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(serial.status),
                ),
              ),
            ),
          ],
        ),
        trailing: widget.canManage
            ? PopupMenuButton(
          icon: Icon(Icons.more_vert),
          itemBuilder: (context) => [
            ...SerialStatus.values.map((status) => PopupMenuItem(
              value: status,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Mark as ${status.displayName}'),
                ],
              ),
            ))
          ],
          onSelected: (SerialStatus status) {
            context.read<SerialNumberBloc>().add(BulkUpdateSerialStatus([serial.id], status));
          },
        )
            : null, // ✅ No menu for viewers

      ),
    );
  }

  Widget _buildSerialPreview() {
    return BlocBuilder<SerialNumberBloc, SerialNumberState>(
      builder: (context, state) {
        // ✅ Get current count from BLoC state
        int existingCount = 0;

        if (state is SerialNumbersLoaded) {
          existingCount = state.serials.length;
        } else {
          existingCount = widget.item.serialNumbers.length;
        }

        final nextNumber = existingCount + 1;
        final previewSerial =
            '${widget.item.sku}-${nextNumber.toString().padLeft(6, '0')}';

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[50]!, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue[700], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Next Serial Preview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                previewSerial,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return BlocBuilder<SerialNumberBloc, SerialNumberState>(
      builder: (context, state) {
        // ✅ Get serials from BLoC state, not from widget.item
        List<SerialNumber> serials = [];

        if (state is SerialNumbersLoaded) {
          serials = state.serials;
        } else {
          serials = widget.item.serialNumbers;
        }

        final available = serials
            .where((s) => s.status == SerialStatus.available)
            .length;
        final sold = serials.where((s) => s.status == SerialStatus.sold).length;
        final rented = serials
            .where((s) => s.status == SerialStatus.rented)
            .length;
        final damaged = serials
            .where((s) => s.status == SerialStatus.damaged)
            .length;

        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              _buildStatusChip('Total', serials.length, Colors.grey, Icons.tag),
              SizedBox(width: 8),
              _buildStatusChip(
                'Available',
                available,
                Colors.green,
                Icons.check_circle,
              ),
              SizedBox(width: 8),
              _buildStatusChip('Sold', sold, Colors.blue, Icons.shopping_cart),
              SizedBox(width: 8),
              _buildStatusChip(
                'Rented',
                rented,
                Colors.purple,
                Icons.access_time,
              ),
              SizedBox(width: 8),
              _buildStatusChip(
                'Damaged',
                damaged,
                Colors.red,
                Icons.broken_image,
              ),
              Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, int count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
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
      case SerialStatus.damaged:
        return Colors.red;
      case SerialStatus.rented:
        return Colors.purple;
      case SerialStatus.returned:
        return Colors.amber;
      case SerialStatus.recalled:
        return Colors.red[900]!;
    }
  }

  void _generateSerials() {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showError('Please enter a valid quantity');
      return;
    }

    // ✅ Get current count from BLoC state
    final currentState = context.read<SerialNumberBloc>().state;
    int existingCount = 0;

    if (currentState is SerialNumbersLoaded) {
      existingCount = currentState.serials.length;
    } else {
      existingCount = widget.item.serialNumbers.length;
    }

    final serials = List.generate(quantity, (i) {
      final serialNumber = existingCount + i + 1;
      final formattedSerial =
          '${widget.item.sku}-${serialNumber.toString().padLeft(6, '0')}';

      return SerialNumber(
        id: '',
        itemId: widget.item.id,
        serialNumber: formattedSerial,
        status: SerialStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    context.read<SerialNumberBloc>().add(
      AddSerialNumbers(widget.item.id, serials),
    );
    _quantityController.clear();
  }

  void _addManualSerial() {
    final serialText = _manualSerialController.text.trim();
    if (serialText.isEmpty) {
      _showError('Please enter a serial number');
      return;
    }

    final serial = SerialNumber(
      id: '',
      itemId: widget.item.id,
      serialNumber: serialText,
      status: SerialStatus.available,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<SerialNumberBloc>().add(
      AddSerialNumbers(widget.item.id, [serial]),
    );
    _manualSerialController.clear();
  }

  void _bulkUpdateStatus(SerialStatus status) {
    context.read<SerialNumberBloc>().add(
      BulkUpdateSerialStatus(_selectedSerials, status),
    );
    setState(() => _selectedSerials.clear());
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
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
