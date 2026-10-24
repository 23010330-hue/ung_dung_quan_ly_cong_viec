import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart' show Hive;
import 'package:image_picker/image_picker.dart';
import 'package:todoapp/data/database.dart';
import 'package:todoapp/pages/about_page.dart';
import 'package:todoapp/pages/history_page.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/dialog_box.dart';
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
      default:
        return text;
    }
  }
  @override
  void initState() {
    _colorTheme = AppColorTheme.fromId(_myBox.get('APP_COLOR_THEME'));
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
  static const _filterOptions = ['Tất cả', 'Ngày', 'Tuần', 'Tháng', 'Năm'];

  bool get _hasBackgroundImage =>
      _backgroundImageBytes != null && _backgroundImageBytes!.isNotEmpty;

  /// Ngày đang xem: ngày chọn trên lịch, hoặc hôm nay nếu chưa chọn.
  String get _viewDate => _selectedDateFilter ?? db.getToday();

  bool _shouldShowTask(
    String taskCategory,
    String taskDate,
    bool taskCompleted,
  ) {
    if (!db.taskMatchesPeriod(taskCategory, taskDate, _viewDate)) {
      return false;
    }
    if (_currentFilter == 'Tất cả') {
      return !taskCompleted;
    }
    return taskCategory == _currentFilter;
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
  void saveNewTask() {
    final taskName = _controller.text.trim();
    if (taskName.isEmpty) return;

    setState(() {
      db.toDoList.add([
        taskName,
        false,
        _selectedCategory,
        _selectedTaskDate,
        null,
      ]);
      _controller.clear();
      _selectedCategory = 'Ngày';
      _selectedTaskDate = db.getToday();
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

  void createNewTask() {
    _selectedTaskDate = _viewDate;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return DialogBox(
              controller: _controller,
              onSave: saveNewTask,
              onCancel: () {
                Navigator.of(context).pop();
                _controller.clear();
                _selectedTaskDate = db.getToday();
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
    setState(() {
      db.toDoList.removeAt(index);
    });
    db.updateData();
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
          backgroundColor: _colorTheme.primary,
          title: Text(
            translate('Chọn màu giao diện'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
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
                          color: isSelected ? Colors.black : Colors.white,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.black)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theme.label(isVietnamese),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
              child: Text(translate('Hủy')),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorTheme.light,
      appBar: AppBar(
        title: Text(translate('Việc Cần Làm')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _colorTheme.primary,
        foregroundColor: Colors.black,
        actions: [
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
            child: DropdownButton<String>(
              dropdownColor: _colorTheme.primary,
              icon: const Icon(Icons.filter_list, color: Colors.black),
              value: _currentFilter,
              items: _filterOptions.map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    translate(value),
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.black),
            tooltip: translate('Cài đặt'),
            color: _colorTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'language') {
                setState(() {
                  isVietnamese = !isVietnamese;
                });
              } else if (value == 'color') {
                _showColorPicker();
              } else if (value == 'background') {
                _pickBackgroundImage();
              } else if (value == 'remove_background') {
                _removeBackgroundImage();
              } else if (value == 'history') {
                _openHistoryPage();
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
                  child: Row(
                    children: [
                      const Icon(Icons.language, color: Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        isVietnamese
                            ? 'Ngôn ngữ: 🇻🇳 VN'
                            : 'Language: 🇬🇧 EN',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'color',
                  child: Row(
                    children: [
                      const Icon(Icons.palette, color: Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        translate('Đổi màu giao diện'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'background',
                  child: Row(
                    children: [
                      const Icon(Icons.wallpaper, color: Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        translate('Đổi ảnh nền'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (_hasBackgroundImage)
                  PopupMenuItem<String>(
                    value: 'remove_background',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.image_not_supported,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          translate('Xóa ảnh nền'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem<String>(
                  value: 'history',
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        translate('Lịch sử công việc'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'about',
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        translate('Giới thiệu'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        backgroundColor: _colorTheme.primary,
        foregroundColor: Colors.black,
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
              Container(
                width: double.infinity,
                color: _colorTheme.dark,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _currentFilter == 'Tất cả'
                      ? "${translate('Đang xem tất cả việc chưa hoàn thành:')} $_viewDate"
                      : _selectedDateFilter != null
                      ? "${translate('Đang xem công việc của ngày:')} $_viewDate"
                      : "${translate('Đang xem công việc của hôm nay:')} $_viewDate",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: db.toDoList.length,
                  itemBuilder: (context, index) {
                    String taskName = db.toDoList[index][0];
                    bool taskCompleted = db.toDoList[index][1];
                    String taskCategory = db.toDoList[index][2];
                    String taskDate = db.toDoList[index][3];
                    if (!_shouldShowTask(
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
