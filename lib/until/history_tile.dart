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
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: onRestore == null ? null : (_) => onRestore!(),
              icon: Icons.undo,
              backgroundColor: const Color(0xFF81C784),
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            SlidableAction(
              onPressed: deleteFunction,
              icon: Icons.delete_outline,
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorTheme.dark.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 6, color: colorTheme.primary),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: colorTheme.dark,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  taskName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black45,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.done_all,
                                      size: 14,
                                      color: Colors.grey[700],
                                    ),
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
                                    Icon(
                                      Icons.event,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$scheduledLabel $scheduledDate',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorTheme.light,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorTheme.dark
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    taskCategory,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colorTheme.dark,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}