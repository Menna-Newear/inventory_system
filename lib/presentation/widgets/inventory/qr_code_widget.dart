// presentation/widgets/inventory/enhanced_qr_code_widget.dart (ENHANCED & LOCALIZED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../data/services/qr_code_service.dart';
import '../../../domain/entities/inventory_item.dart';

class EnhancedQrCodeWidget extends StatefulWidget {
  final InventoryItem item;
  final double size;
  final bool showControls;
  final bool showItemInfo;

  const EnhancedQrCodeWidget({
    Key? key,
    required this.item,
    this.size = 200.0,
    this.showControls = false,
    this.showItemInfo = true,
  }) : super(key: key);

  @override
  State<EnhancedQrCodeWidget> createState() => _EnhancedQrCodeWidgetState();
}

class _EnhancedQrCodeWidgetState extends State<EnhancedQrCodeWidget> with SingleTickerProviderStateMixin {
  final qrService = EnhancedQrCodeService();
  QrCodeShape selectedShape = QrCodeShape.rounded;
  List<Color> selectedGradient = [Colors.blue, Colors.purple];
  bool showWithLogo = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code Display with Animation
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.1),
                  spreadRadius: 3,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                _buildSelectedQrCode(),
                if (widget.showItemInfo) ...[
                  SizedBox(height: 16),
                  _buildItemInfo(),
                ],
              ],
            ),
          ),
        ),

        if (widget.showControls) ...[
          SizedBox(height: 20),
          _buildControlPanel(),
        ],
      ],
    );
  }

  Widget _buildSelectedQrCode() {
    return Hero(
      tag: 'qr_${widget.item.id}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: qrService.generateQrCodeWithLogo(
            widget.item,
            size: widget.size,
            centerImage: showWithLogo ? _buildLogoWidget() : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoWidget() {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Image.asset(
        "assets/white logo icon.png",
        width: 28,
        height: 28,
      ),
    );
  }

  Widget _buildControlPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? theme.cardColor : Colors.white,
              isDark ? theme.cardColor : theme.primaryColor.withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.style, color: theme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'qr_code.style_title'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Shape Selection
              Text(
                'Shape:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: QrCodeShape.values.map((shape) {
                  return _buildShapeChip(shape, theme);
                }).toList(),
              ),

              SizedBox(height: 16),

              // Color Selection
              Text(
                'qr_code.color_theme'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildColorOption([Colors.black, Colors.grey]),
                    _buildColorOption([Colors.blue, Colors.purple]),
                    _buildColorOption([Colors.green, Colors.teal]),
                    _buildColorOption([Colors.red, Colors.pink]),
                    _buildColorOption([Colors.orange, Colors.yellow]),
                    _buildColorOption([Colors.indigo, Colors.cyan]),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Logo Toggle
              Container(
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(
                    'qr_code.add_logo'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: showWithLogo,
                  onChanged: (value) {
                    setState(() {
                      showWithLogo = value;
                      _animationController.reset();
                      _animationController.forward();
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  activeColor: theme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShapeChip(QrCodeShape shape, ThemeData theme) {
    final isSelected = selectedShape == shape;

    return FilterChip(
      label: Text(_getShapeLabel(shape)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedShape = shape;
            _animationController.reset();
            _animationController.forward();
          });
        }
      },
      selectedColor: theme.primaryColor.withOpacity(0.2),
      checkmarkColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? theme.primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildColorOption(List<Color> colors) {
    final isSelected = selectedGradient.first == colors.first;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGradient = colors;
          _animationController.reset();
          _animationController.forward();
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 48,
        height: 48,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ]
              : [],
        ),
        child: isSelected
            ? Icon(Icons.check, color: Colors.white, size: 24)
            : null,
      ),
    );
  }

  Widget _buildItemInfo() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = context.locale;
    final isArabic = locale.languageCode == 'ar';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.05),
            theme.primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic && widget.item.nameAr.isNotEmpty
                ? widget.item.nameAr
                : widget.item.nameEn,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if ((isArabic && widget.item.nameEn.isNotEmpty) ||
              (!isArabic && widget.item.nameAr.isNotEmpty)) ...[
            SizedBox(height: 4),
            Text(
              isArabic ? widget.item.nameEn : widget.item.nameAr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                '${'qr_code.sku_label'.tr()} ${widget.item.sku}',
                Icons.qr_code_scanner,
                theme,
              ),
              if (widget.item.unitPrice != null)
                _buildInfoChip(
                  widget.item.displayPrice,
                  Icons.attach_money,
                  theme,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.primaryColor),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getShapeLabel(QrCodeShape shape) {
    switch (shape) {
      case QrCodeShape.rounded:
        return 'qr_code.shape_rounded'.tr();
      case QrCodeShape.circles:
        return 'qr_code.shape_circles'.tr();
      case QrCodeShape.squares:
        return 'qr_code.shape_squares'.tr();
      case QrCodeShape.mixed:
        return 'qr_code.shape_mixed'.tr();
    }
  }
}
