import 'package:flutter/material.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/app_dropdown.dart';

class DialogBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String selectedCategory;
  final Function(String?) onCategoryChanged;
  final String selectedTaskDate;
  final VoidCallback onPickTaskDate;
  final String Function(String) translate;
  final AppColorTheme colorTheme;
  final String? title;

  const DialogBox({
    super.key,
    this.title,
    required this.controller,
    required this.onSave,
    required this.onCancel,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedTaskDate,
    required this.onPickTaskDate,
    required this.translate,
    required this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF2D2A26);

    return AlertDialog(
      backgroundColor: colorTheme.light,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorTheme.dark,
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: translate('Thêm Công Việc'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorTheme.dark, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  translate('Ngày thực hiện:'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onPickTaskDate,
                icon: Icon(Icons.calendar_today, size: 16, color: colorTheme.dark),
                label: Text(
                  selectedTaskDate,
                  style: TextStyle(color: colorTheme.dark),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: colorTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  translate('Phân Loại:'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorTheme.primary),
                ),
                child: AppDropdown<String>(
                  value: selectedCategory,
                  items: const ['Ngày', 'Tuần', 'Tháng', 'Năm'],
                  labelBuilder: translate,
                  dropdownColor: Colors.white,
                  onChanged: onCategoryChanged,
                ),
              ),
            ],
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            translate('Hủy'),
            style: TextStyle(color: colorTheme.dark),
          ),
        ),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorTheme.dark,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(translate('Lưu')),
        ),
      ],
    );
  }
}