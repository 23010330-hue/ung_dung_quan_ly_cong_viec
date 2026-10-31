import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:todoapp/theme/app_colors.dart';

class ToDoTile extends StatelessWidget {
  final String taskName;
  final bool taskCompleted;
  final String taskCategory;
  final String taskDate;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? deleteFunction;
  final AppColorTheme colorTheme;
  final VoidCallback? onTap;

  const ToDoTile({
    super.key,
    required this.taskName,
    required this.taskCompleted,
    required this.taskCategory,
    required this.taskDate,
    required this.onChanged,
    required this.deleteFunction,
    required this.colorTheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF2D2A26);
    final titleColor = taskCompleted ? Colors.black45 : textColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: deleteFunction,
              icon: Icons.delete_outline,
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
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
                  // dải màu chủ đề bên trái
                  Container(width: 6, color: colorTheme.primary),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
                      child: Row(
                        children: [
                          Checkbox(
                            value: taskCompleted,
                            onChanged: onChanged,
                            shape: const CircleBorder(),
                            activeColor: colorTheme.dark,
                            side: BorderSide(color: colorTheme.dark, width: 1.5),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  taskName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: titleColor,
                                    decoration: taskCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
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
                                    const SizedBox(width: 10),
                                    Icon(
                                      Icons.event,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      taskDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}