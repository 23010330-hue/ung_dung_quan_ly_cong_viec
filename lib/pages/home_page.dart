import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart' show Hive;
import 'package:image_picker/image_picker.dart';
import 'package:todoapp/data/database.dart';
import 'package:todoapp/pages/about_page.dart';
import 'package:todoapp/pages/history_page.dart';
import 'package:todoapp/pages/stats_page.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/dialog_box.dart';
import 'package:todoapp/until/task_search_field.dart';
import 'package:todoapp/until/todo_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _myBox = Hive.box('box_v3');
  ToDoDaTaBase db = ToDoDaTaBase();
  bool isVietnamese = true;
  late AppColorTheme _colorTheme;
  Uint8List? _backgroundImageBytes;
  final _imagePicker = ImagePicker();

  String translate(String text) {
    if (isVietnamese) return text;
    switch (text) {
      case 'Việc Cần Làm':
        return 'To-Do List';
      case 'Ngày':
        return 'Daily';
      case 'Tuần':
        return 'Weekly';
      case 'Tháng':
        return 'Monthly';
      case 'Năm':
        return 'Yearly';
      case 'Tất cả':
        return 'All';
      case 'Bỏ xem lịch sử':
        return 'Clear Date Filter';
      case 'Xem lịch sử theo ngày':
        return 'Select Date';
      case 'Đang xem công việc của ngày:':
        return 'Viewing tasks for date:';
      case 'Thêm Công Việc':
        return 'Add Task';
      case 'Phân Loại:':
        return 'Category:';
      case 'Lưu':
        return 'Save';
      case 'Hủy':
        return 'Cancel';
      case 'Cài đặt':
        return 'Settings';
      case 'Giới thiệu':
        return 'About Us';
      case 'Thông tin nhóm':
        return 'Group Information';
      case 'Tên nhóm:':
        return 'Group Name:';
      case 'Thành viên:':
        return 'Members:';
      case 'Đổi ảnh nền':
        return 'Change Background';
      case 'Xóa ảnh nền':
        return 'Remove Background';
      case 'Đổi màu giao diện':
        return 'Change Theme Color';
      case 'Chọn màu giao diện':
        return 'Pick a theme color';
      case 'Ngày thực hiện:':
        return 'Scheduled date:';
      case 'Chọn ngày ghi chú':
        return 'Pick note date';
      case 'Đang xem công việc của hôm nay:':
        return "Viewing today's tasks:";
      case 'Đang xem tất cả việc chưa hoàn thành:':
        return 'Viewing all incomplete tasks:';
      case 'Lịch sử công việc':
        return 'Task History';
      case 'Hoàn thành:':
        return 'Completed:';
      case 'Kế hoạch:':
        return 'Scheduled:';
      case 'Chưa có công việc đã hoàn thành':
        return 'No completed tasks yet';
      case 'Xem lịch sử hoàn thành':
        return 'View completed history';
      case 'Thống kê':
        return 'Statistics';
      case 'Tổng số việc':
        return 'Total tasks';
      case 'Đã hoàn thành':
        return 'Completed';
      case 'Chưa hoàn thành':
        return 'Pending';
      case 'Tỉ lệ hoàn thành':
        return 'Completion rate';
      case 'Hoàn thành 7 ngày qua':
        return 'Completed in the last 7 days';
      case 'Theo phân loại':
        return 'By category';
      case 'Tìm kiếm':
        return 'Search';
      case 'Tìm công việc...':
        return 'Search tasks...';
      case 'Đóng tìm kiếm':
        return 'Close search';
      case 'Kết quả tìm kiếm cho:':
        return 'Search results for:';
      case 'Không tìm thấy việc nào':
        return 'No tasks found';
      case 'Thử từ khóa khác':
        return 'Try a different keyword';
      case 'Sửa công việc':
        return 'Edit Task';
      case 'Đã xóa công việc':
        return 'Task deleted';
      case 'Hoàn tác':
        return 'Undo';
      case 'Chưa có việc nào':
        return 'Nothing to do yet';
      case 'Bấm + để thêm công việc mới':
        return 'Tap + to add a new task';
      default:
        return text;
    }
  }

  @override
  void initState() {
    _colorTheme = AppColorTheme.fromId(_myBox.get('APP_COLOR_THEME'));
    isVietnamese = _myBox.get('IS_VIETNAMESE', defaultValue: true) as bool;
    final storedBytes = _myBox.get('BACKGROUND_IMAGE_BYTES');
    if (storedBytes != null) {
      _backgroundImageBytes = Uint8List.fromList(List<int>.from(storedBytes));
    }
    if (_myBox.get("TODOLIST") == null) {
      db.createInitialData();
    } else {
      db.loadData();
    }
    super.initState();
  }

  final _controller = TextEditingController();
  String _selectedCategory = 'Ngày';
  String _currentFilter = 'Tất cả';
  String? _selectedDateFilter;
  String _selectedTaskDate = '';
  int? _editingIndex; // null = đang thêm mới, khác null = đang sửa việc này
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  static const _filterOptions = ['Tất cả', 'Ngày', 'Tuần', 'Tháng', 'Năm'];

  bool get _hasBackgroundImage =>
      _backgroundImageBytes != null && _backgroundImageBytes!.isNotEmpty;

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
    // Đang tìm kiếm: tìm trong mọi việc chưa hoàn thành, bỏ qua bộ lọc ngày
    if (_searchQuery.isNotEmpty) {
      return !taskCompleted &&
          taskName.toLowerCase().contains(_searchQuery.toLowerCase());
    }
    if (!db.taskMatchesPeriod(taskCategory, taskDate, _viewDate)) {
      return false;
    }
    if (_currentFilter == 'Tất cả') {
      return !taskCompleted;
    }
    return taskCategory == _currentFilter;
  }

  bool get _hasVisibleTasks => db.toDoList.any(
        (task) => _shouldShowTask(task[0], task[2], task[3], task[1]),
      );

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
    setState(() {
      final newCompleted = !db.toDoList[index][1];
      db.setTaskCompleted(db.toDoList[index], newCompleted);
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
        // đang sửa: chỉ đổi tên, phân loại, ngày; giữ nguyên trạng thái hoàn thành
        db.toDoList[editIndex][0] = taskName;
        db.toDoList[editIndex][2] = _selectedCategory;
        db.toDoList[editIndex][3] = _selectedTaskDate;
      } else {
        db.toDoList.add([
          taskName,
          false,
          _selectedCategory,
          _selectedTaskDate,
          null,
        ]);
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

  /// Mở hộp thoại thêm việc mới, hoặc sửa việc có chỉ số [editIndex].
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
    final removed = db.toDoList[index];
    setState(() {
      db.toDoList.removeAt(index);
    });
    db.updateData();

    final messenger = ScaffoldMessenger.of(context);
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
            setState(() {
              final at = index > db.toDoList.length
                  ? db.toDoList.length
                  : index;
              db.toDoList.insert(at, removed);
            });
            db.updateData();
          },
        ),
      ),
    );
  }

  Future<void> _pickBackgroundImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _backgroundImageBytes = bytes;
    });
    await _myBox.put('BACKGROUND_IMAGE_BYTES', bytes);
  }

  Future<void> _removeBackgroundImage() async {
    setState(() {
      _backgroundImageBytes = null;
    });
    await _myBox.delete('BACKGROUND_IMAGE_BYTES');
  }

  void _selectColorTheme(AppColorTheme theme) {
    setState(() {
      _colorTheme = theme;
    });
    _myBox.put('APP_COLOR_THEME', theme.id);
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _colorTheme.light,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            translate('Chọn màu giao diện'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2A26),
            ),
          ),
          content: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: AppColorTheme.themes.map((theme) {
              final isSelected = theme.id == _colorTheme.id;
              return GestureDetector(
                onTap: () {
                  _selectColorTheme(theme);
                  Navigator.of(context).pop();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? theme.dark : Colors.white,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.dark.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: theme.dark)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theme.label(isVietnamese),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2A26),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                translate('Hủy'),
                style: TextStyle(color: _colorTheme.dark),
              ),
            ),
          ],
        );
      },
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

  Widget _menuItemRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2D2A26)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2A26),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.only(right: 4.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: _colorTheme.light,
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.filter_list, color: Colors.black),
                value: _currentFilter,
                items: _filterOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      translate(value),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2A26),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _currentFilter = newValue!;
                  });
                },
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.black),
            tooltip: translate('Cài đặt'),
            color: _colorTheme.light,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'language') {
                setState(() {
                  isVietnamese = !isVietnamese;
                });
                _myBox.put('IS_VIETNAMESE', isVietnamese);
              } else if (value == 'color') {
                _showColorPicker();
              } else if (value == 'background') {
                _pickBackgroundImage();
              } else if (value == 'remove_background') {
                _removeBackgroundImage();
              } else if (value == 'history') {
                _openHistoryPage();
              } else if (value == 'stats') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatsPage(
                      db: db,
                      translate: translate,
                      colorTheme: _colorTheme,
                    ),
                  ),
                );
              } else if (value == 'about') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AboutPage(
                      translate: translate,
                      colorTheme: _colorTheme,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'language',
                  child: _menuItemRow(
                    Icons.language,
                    isVietnamese ? 'Ngôn ngữ: 🇻🇳 VN' : 'Language: 🇬🇧 EN',
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'color',
                  child: _menuItemRow(
                    Icons.palette,
                    translate('Đổi màu giao diện'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'background',
                  child: _menuItemRow(
                    Icons.wallpaper,
                    translate('Đổi ảnh nền'),
                  ),
                ),
                if (_hasBackgroundImage)
                  PopupMenuItem<String>(
                    value: 'remove_background',
                    child: _menuItemRow(
                      Icons.image_not_supported,
                      translate('Xóa ảnh nền'),
                    ),
                  ),
                PopupMenuItem<String>(
                  value: 'history',
                  child: _menuItemRow(
                    Icons.history,
                    translate('Lịch sử công việc'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'stats',
                  child: _menuItemRow(
                    Icons.bar_chart,
                    translate('Thống kê'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'about',
                  child: _menuItemRow(
                    Icons.info_outline,
                    translate('Giới thiệu'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        backgroundColor: _colorTheme.dark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasBackgroundImage)
            Image.memory(
              _backgroundImageBytes!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            )
          else
            ColoredBox(color: _colorTheme.light),
          if (_hasBackgroundImage)
            ColoredBox(color: Colors.black.withValues(alpha: 0.25)),
          Column(
            children: [
              // Dải thông báo dạng thẻ bo góc
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
              Expanded(
                child: !_hasVisibleTasks
                    ? _buildEmptyState()
                    : ListView.builder(
                  // chừa chỗ cho nút + không che ô việc cuối
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
        ],
      ),
    );
  }
}