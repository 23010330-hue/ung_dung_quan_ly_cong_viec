import 'package:flutter/material.dart';
import 'package:todoapp/data/database.dart';
import 'package:todoapp/pages/history_page.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/app_dropdown.dart';
import 'package:todoapp/until/dialog_box.dart';
import 'package:todoapp/until/task_search_field.dart';
import 'package:todoapp/until/todo_tile.dart';

/// Chế độ "Đặt lịch": danh sách việc cần làm.
class SchedulePage extends StatefulWidget {
  final ToDoDaTaBase db;
  final String Function(String) translate;
  final AppColorTheme colorTheme;

  const SchedulePage({
    super.key,
    required this.db,
    required this.translate,
    required this.colorTheme,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  ToDoDaTaBase get db => widget.db;
  String Function(String) get translate => widget.translate;
  AppColorTheme get _colorTheme => widget.colorTheme;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  final _controller = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedCategory = 'Ngày';
  String _currentFilter = 'Tất cả';
  String? _selectedDateFilter;
  String _selectedTaskDate = '';
  int? _editingIndex; 
  bool _isSearching = false;
  String _searchQuery = '';
  static const _filterOptions = ['Tất cả', 'Ngày', 'Tuần', 'Tháng', 'Năm'];

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Ngày đang xem: ngày chọn trên lịch, hoặc hôm nay nếu chưa chọn.
  String get _viewDate => _selectedDateFilter ?? db.getToday();

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  bool _shouldShowTask(
    String taskName,
    String taskCategory,
    String taskDate,
    bool taskCompleted,
  ) {
    return db.shouldShowTask(
      name: taskName,
      category: taskCategory,
      date: taskDate,
      completed: taskCompleted,
      viewDate: _viewDate,
      filter: _currentFilter,
      query: _searchQuery,
    );
  }

  bool get _hasVisibleTasks {
    for (final task in db.toDoList) {
      if (_shouldShowTask(task[0], task[2], task[3], task[1])) {
        return true;
      }
    }
    return false;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt,
              size: 56,
              color: _colorTheme.dark.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? translate('Không tìm thấy việc nào')
                  : translate('Chưa có việc nào'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2A26),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? translate('Thử từ khóa khác')
                  : translate('Bấm + để thêm công việc mới'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  void checkBoxChanged(bool? value, int index) {
    final task = db.toDoList[index];
    final newCompleted = !(task[1] as bool);
    setState(() {
      db.setTaskCompleted(task, newCompleted);
    });
    db.updateData();
  }

  void _openHistoryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryPage(
          db: db,
          translate: translate,
          colorTheme: _colorTheme,
          onDataChanged: () => setState(() {}),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _saveTask() {
    final taskName = _controller.text.trim();
    if (taskName.isEmpty) return;

    setState(() {
      final editIndex = _editingIndex;
      if (editIndex != null && editIndex < db.toDoList.length) {
        db.editTask(
          editIndex,
          name: taskName,
          category: _selectedCategory,
          date: _selectedTaskDate,
        );
      } else {
        db.addTask(taskName, _selectedCategory, _selectedTaskDate);
      }
      _controller.clear();
      _selectedCategory = 'Ngày';
      _selectedTaskDate = db.getToday();
      _editingIndex = null;
    });
    Navigator.of(context).pop();
    db.updateData();
  }

  Future<void> _pickTaskDate(StateSetter setStateDialog) async {
    final initialDate = db.parseDate(_selectedTaskDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: translate('Chọn ngày ghi chú'),
    );
    if (picked != null) {
      setStateDialog(() {
        _selectedTaskDate = db.formatDate(picked);
      });
    }
  }

  void createNewTask() => _openTaskDialog();

  /// Mở hộp thoại thêm việc mới
  void _openTaskDialog({int? editIndex}) {
    _editingIndex = editIndex;
    if (editIndex != null) {
      final task = db.toDoList[editIndex];
      _controller.text = task[0] as String;
      _selectedCategory = task[2] as String;
      _selectedTaskDate = task[3] as String;
    } else {
      _controller.clear();
      _selectedCategory = 'Ngày';
      _selectedTaskDate = _viewDate;
    }
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return DialogBox(
              title: editIndex != null ? translate('Sửa công việc') : null,
              controller: _controller,
              onSave: _saveTask,
              onCancel: () {
                Navigator.of(context).pop();
                _controller.clear();
                _selectedCategory = 'Ngày';
                _selectedTaskDate = db.getToday();
                _editingIndex = null;
              },
              selectedCategory: _selectedCategory,
              onCategoryChanged: (String? newValue) {
                setStateDialog(() {
                  _selectedCategory = newValue!;
                });
              },
              selectedTaskDate: _selectedTaskDate,
              onPickTaskDate: () => _pickTaskDate(setStateDialog),
              translate: translate,
              colorTheme: _colorTheme,
            );
          },
        );
      },
    );
  }

  void deleteTask(int index) {
    final removed = db.removeTask(index);
    if (removed == null) return;
    setState(() {});
    db.updateData();

    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(translate('Đã xóa công việc')),
        backgroundColor: _colorTheme.dark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: translate('Hoàn tác'),
          textColor: Colors.white,
          onPressed: () {
            setState(() => db.restoreTask(index, removed));
            db.updateData();
          },
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDateFilter = db.formatDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: _colorTheme.light,
        appBar: AppBar(
          title: _isSearching
              ? TaskSearchField(
                  controller: _searchController,
                  hint: translate('Tìm công việc...'),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                )
              : Text(
                  translate('Việc Cần Làm'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: _colorTheme.primary,
          foregroundColor: Colors.black,
          actions: _isSearching
              ? [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    tooltip: translate('Đóng tìm kiếm'),
                    onPressed: _stopSearch,
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    tooltip: translate('Tìm kiếm'),
                    onPressed: _startSearch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.black),
                    tooltip: translate('Xem lịch sử hoàn thành'),
                    onPressed: _openHistoryPage,
                  ),
                  if (_selectedDateFilter != null)
                    IconButton(
                      icon: const Icon(Icons.event_busy, color: Colors.red),
                      tooltip: translate('Bỏ xem lịch sử'),
                      onPressed: () {
                        setState(() {
                          _selectedDateFilter = null;
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month, color: Colors.black),
                    tooltip: translate('Xem lịch sử theo ngày'),
                    onPressed: () => _selectDate(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: AppDropdown<String>(
                      value: _currentFilter,
                      items: _filterOptions,
                      labelBuilder: translate,
                      dropdownColor: _colorTheme.light,
                      icon: const Icon(Icons.filter_list, color: Colors.black),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2A26),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _currentFilter = newValue!;
                        });
                      },
                    ),
                  ),
                ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: createNewTask,
          backgroundColor: _colorTheme.dark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _colorTheme.dark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _searchQuery.isNotEmpty
                      ? "${translate('Kết quả tìm kiếm cho:')} '$_searchQuery'"
                      : _currentFilter == 'Tất cả'
                      ? "${translate('Đang xem tất cả việc chưa hoàn thành:')} $_viewDate"
                      : _selectedDateFilter != null
                      ? "${translate('Đang xem công việc của ngày:')} $_viewDate"
                      : "${translate('Đang xem công việc của hôm nay:')} $_viewDate",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: !_hasVisibleTasks
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: db.toDoList.length,
                      itemBuilder: (context, index) {
                        String taskName = db.toDoList[index][0];
                        bool taskCompleted = db.toDoList[index][1];
                        String taskCategory = db.toDoList[index][2];
                        String taskDate = db.toDoList[index][3];
                        if (!_shouldShowTask(
                          taskName,
                          taskCategory,
                          taskDate,
                          taskCompleted,
                        )) {
                          return const SizedBox.shrink();
                        }
                        return ToDoTile(
                          taskName: taskName,
                          taskCompleted: taskCompleted,
                          taskCategory: translate(taskCategory),
                          taskDate: taskDate,
                          onChanged: (value) => checkBoxChanged(value, index),
                          deleteFunction: (context) => deleteTask(index),
                          onTap: () => _openTaskDialog(editIndex: index),
                          colorTheme: _colorTheme,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
