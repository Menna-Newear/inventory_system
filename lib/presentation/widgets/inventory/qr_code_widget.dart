// presentation/widgets/inventory/enhanced_qr_code_widget.dart
import 'package:flutter/material.dart';
import '../../../data/services/qr_code_service.dart';
import '../../../domain/entities/inventory_item.dart';

class EnhancedQrCodeWidget extends StatefulWidget {
  final InventoryItem item;
  final double size;
  final bool showControls;

  const EnhancedQrCodeWidget({
    Key? key,
    required this.item,
    this.size = 200.0,
    this.showControls = true,
  }) : super(key: key);

  @override
  State<EnhancedQrCodeWidget> createState() => _EnhancedQrCodeWidgetState();
}

class _EnhancedQrCodeWidgetState extends State<EnhancedQrCodeWidget> {
  final qrService = EnhancedQrCodeService();
  QrCodeShape selectedShape = QrCodeShape.rounded;
  List<Color> selectedGradient = [Colors.blue, Colors.purple];
  bool showWithLogo = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code Display
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: _buildSelectedQrCode(),
        ),

        /*        if (widget.showControls) ...[
          SizedBox(height: 16),
          _buildControlPanel(),
        ],*/
        SizedBox(height: 16),
       // _buildItemInfo(),
      ],
    );
  }

  Widget _buildSelectedQrCode() {
    return qrService.generateQrCodeWithLogo(
      widget.item,
      size: widget.size,
      centerImage: _buildLogoWidget(),
    );

    /*
    if (showWithLogo) {
      return qrService.generateQrCodeWithLogo(
        widget.item,
        size: widget.size,
        centerImage: _buildLogoWidget(),
      );
    } else {
      return qrService.generateCustomShapeQrCode(
        widget.item,
        size: widget.size,
        shape: selectedShape,
        foregroundColor: selectedGradient.first,
      );
    }*/
  }

  Widget _buildLogoWidget() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.inventory_2,
        color: Theme.of(context).primaryColor,
        size: 20,
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QR Code Style',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            /*            // Shape Selection
            Wrap(
              spacing: 8,
              children: QrCodeShape.values.map((shape) {
                return ChoiceChip(
                  label: Text(_getShapeLabel(shape)),
                  selected: selectedShape == shape,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedShape = shape;
                        showWithLogo = true;
                      });
                    }
                  },
                );
              }).toList(),
            ),*/

            /*
            SizedBox(height: 12),

            // Color Selection
            Text('Color Theme:', style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 8),
            Row(
              children: [
                _buildColorOption([Colors.black, Colors.grey]),
                _buildColorOption([Colors.blue, Colors.purple]),
                _buildColorOption([Colors.green, Colors.teal]),
                _buildColorOption([Colors.red, Colors.pink]),
                _buildColorOption([Colors.orange, Colors.yellow]),
              ],
            ),
*/

            /*           SizedBox(height: 12),

            // Logo Option
            CheckboxListTile(
              title: Text('Add Logo'),
              value: showWithLogo,
              onChanged: (value) {
                setState(() {
                  showWithLogo = value ?? false;
                });
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            */
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(List<Color> colors) {
    final isSelected = selectedGradient.first == colors.first;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGradient = colors;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildItemInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.nameEn,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.item.nameAr.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              widget.item.nameAr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
              ),
            ),
          ],
          SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip('SKU: ${widget.item.sku}', Icons.qr_code_scanner),
              SizedBox(width: 8),
              if (widget.item.unitPrice != null)
                _buildInfoChip(widget.item.displayPrice, Icons.attach_money),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).primaryColor),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getShapeLabel(QrCodeShape shape) {
    switch (shape) {
      case QrCodeShape.rounded:
        return 'Rounded';
      case QrCodeShape.circles:
        return 'Circles';
      case QrCodeShape.squares:
        return 'Squares';
      case QrCodeShape.mixed:
        return 'Mixed';
    }
  }
}
