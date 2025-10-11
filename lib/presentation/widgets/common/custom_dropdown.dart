// presentation/widgets/common/custom_dropdown.dart
import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  // ✅ NEW - Added missing parameters
  final String? hint;
  final Widget Function(T)? itemBuilder;
  final String Function(T)? itemToString;

  const CustomDropdown({
    Key? key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    // ✅ NEW - Add these to constructor
    this.hint,
    this.itemBuilder,
    this.itemToString,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint, // ✅ NEW - Add hint text support
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        // ✅ NEW - Add error and disabled borders for consistency
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          // ✅ NEW - Use itemBuilder if provided, otherwise use itemToString or toString
          child: itemBuilder?.call(item) ??
              Text(itemToString?.call(item) ?? item.toString()),
        );
      }).toList(),
      // ✅ NEW - Add isExpanded for better layout
      isExpanded: true,
    );
  }
}
