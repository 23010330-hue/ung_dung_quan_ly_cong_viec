import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:todoapp/theme/app_colors.dart';

class HistoryTile extends StatelessWidget {
  final String taskName;
  final String completedDate;
  final String taskCategory;
  final String scheduledDate;
  final Function(BuildContext)? deleteFunction;
  final VoidCallback? onRestore;
  final AppColorTheme colorTheme;
  final String completedLabel;
  final String scheduledLabel;

  const HistoryTile({
    super.key,
    required this.taskName,
    required this.completedDate,
    required this.taskCategory,
    required this.scheduledDate,
    required this.deleteFunction,
    required this.onRestore,
    required this.colorTheme,
    required this.completedLabel,
    required this.scheduledLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 16.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: onRestore == null ? null : (_) => onRestore!(),
              icon: Icons.undo,
              backgroundColor: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: deleteFunction,
              icon: Icons.delete,
              backgroundColor: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorTheme.primary.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorTheme.dark.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle, color: colorTheme.dark, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.done_all, size: 14, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          '$completedLabel $completedDate',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$scheduledLabel $scheduledDate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorTheme.dark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        taskCategory,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
