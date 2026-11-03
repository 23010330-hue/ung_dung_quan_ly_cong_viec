import 'package:flutter/material.dart';


class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;

  
  final String Function(T item) labelBuilder;
  final ValueChanged<T?> onChanged;
  final Color? dropdownColor;
  final Widget? icon;
  final TextStyle? textStyle;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.dropdownColor,
    this.icon,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        dropdownColor: dropdownColor,
        borderRadius: BorderRadius.circular(12),
        icon: icon ?? const Icon(Icons.arrow_drop_down),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(labelBuilder(item), style: textStyle),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}