import 'package:flutter/material.dart';
import 'package:todoapp/data/database.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/history_tile.dart';

class HistoryPage extends StatefulWidget {
  final ToDoDaTaBase db;
  final String Function(String) translate;
  final AppColorTheme colorTheme;
  final VoidCallback onDataChanged;

  const HistoryPage({
    super.key,
    required this.db,
    required this.translate,
    required this.colorTheme,
    required this.onDataChanged,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<int> _sortedIndices = [];

  @override
  void initState() {
    super.initState();
    _refreshIndices();
  }

  void _refreshIndices() {
    _sortedIndices = widget.db.getCompletedTaskIndices();
  }

  void _deleteTask(int index) {
    setState(() {
      widget.db.toDoList.removeAt(index);
      _refreshIndices();
    });
    widget.db.updateData();
    widget.onDataChanged();
  }

  void _restoreTask(int index) {
    setState(() {
      widget.db.setTaskCompleted(widget.db.toDoList[index], false);
      _refreshIndices();
    });
    widget.db.updateData();
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final completedLabel = widget.translate('Hoàn thành:');
    final scheduledLabel = widget.translate('Kế hoạch:');

    return Scaffold(
      backgroundColor: widget.colorTheme.light,
      appBar: AppBar(
        title: Text(widget.translate('Lịch sử công việc')),
        centerTitle: true,
        backgroundColor: widget.colorTheme.primary,
        foregroundColor: Colors.black,
      ),
      body: _sortedIndices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: widget.colorTheme.dark.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.translate('Chưa có công việc đã hoàn thành'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: _sortedIndices.length,
              itemBuilder: (context, listIndex) {
                final taskIndex = _sortedIndices[listIndex];
                final task = widget.db.toDoList[taskIndex];
                final completedDate =
                    widget.db.getCompletedDate(task) ?? widget.db.getToday();

                return HistoryTile(
                  taskName: task[0] as String,
                  completedDate: completedDate,
                  scheduledDate: task[3] as String,
                  taskCategory: widget.translate(task[2] as String),
                  completedLabel: completedLabel,
                  scheduledLabel: scheduledLabel,
                  colorTheme: widget.colorTheme,
                  onRestore: () => _restoreTask(taskIndex),
                  deleteFunction: (context) => _deleteTask(taskIndex),
                );
              },
            ),
    );
  }
}
