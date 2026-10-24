import 'package:flutter/material.dart';
import 'package:todoapp/theme/app_colors.dart';

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

  const DialogBox({
    super.key,
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
    return AlertDialog(
      backgroundColor: colorTheme.primary,
      content: SizedBox(
        height: 260,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: translate('Thêm Công Việc'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  translate('Ngày thực hiện:'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onPickTaskDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(selectedTaskDate),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  translate('Phân Loại:'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedCategory,
                  items: <String>['Ngày', 'Tuần', 'Tháng', 'Năm'].map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(translate(value)),
                    );
                  }).toList(),
                  onChanged: onCategoryChanged,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MaterialButton(
                  onPressed: onSave,
                  color: colorTheme.dark,
                  textColor: Colors.white,
                  child: Text(translate('Lưu')),
                ),
                const SizedBox(width: 8),
                MaterialButton(
                  onPressed: onCancel,
                  color: colorTheme.dark,
                  textColor: Colors.white,
                  child: Text(translate('Hủy')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
