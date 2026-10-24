import 'package:flutter/material.dart';
import 'package:todoapp/data/database.dart';
import 'package:todoapp/theme/app_colors.dart';

class _DayCount {
  final DateTime date;
  final int count;
  const _DayCount(this.date, this.count);
}

class StatsPage extends StatelessWidget {
  final ToDoDaTaBase db;
  final String Function(String) translate;
  final AppColorTheme colorTheme;

  const StatsPage({
    super.key,
    required this.db,
    required this.translate,
    required this.colorTheme,
  });

  static const _textColor = Color(0xFF2D2A26);
  static const _categories = ['Ngày', 'Tuần', 'Tháng', 'Năm'];

  /// Số việc hoàn thành trong 7 ngày gần nhất (cũ nhất ở đầu, hôm nay ở cuối).
  List<_DayCount> _lastSevenDays(List<List> tasks) {
    final now = DateTime.now();
    final result = <_DayCount>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final key = db.formatDate(date);
      final count = tasks
          .where((t) => t[1] == true && db.getCompletedDate(t) == key)
          .length;
      result.add(_DayCount(date, count));
    }
    return result;
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _textColor,
        ),
      ),
    );
  }

  Widget _summaryTile(IconData icon, String value, String label) {
    return Expanded(
      child: _card(
        child: Column(
          children: [
            Icon(icon, color: colorTheme.dark, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<_DayCount> days) {
    final maxCount = days.fold<int>(1, (m, d) => d.count > m ? d.count : m);
    const maxBarHeight = 110.0;

    return SizedBox(
      height: maxBarHeight + 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < days.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${days[i].count}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: days[i].count == 0
                        ? 4
                        : maxBarHeight * days[i].count / maxCount,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      // cột cuối cùng là hôm nay, tô đậm hơn
                      color: i == days.length - 1
                          ? colorTheme.dark
                          : colorTheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${days[i].date.day}/${days[i].date.month}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category, List<List> tasks) {
    final inCategory = tasks.where((t) => t[2] == category).toList();
    final total = inCategory.length;
    final done = inCategory.where((t) => t[1] == true).length;
    final value = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  translate(category),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
              ),
              Text(
                '$done/$total',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorTheme.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: colorTheme.light,
              valueColor: AlwaysStoppedAnimation<Color>(colorTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = db.toDoList.cast<List>();
    final total = tasks.length;
    final done = tasks.where((t) => t[1] == true).length;
    final pending = total - done;
    final rate = total == 0 ? 0 : (done * 100 / total).round();
    final days = _lastSevenDays(tasks);

    return Scaffold(
      backgroundColor: colorTheme.light,
      appBar: AppBar(
        title: Text(
          translate('Thống kê'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorTheme.primary,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _summaryTile(
                Icons.list_alt,
                '$total',
                translate('Tổng số việc'),
              ),
              const SizedBox(width: 12),
              _summaryTile(
                Icons.check_circle_outline,
                '$done',
                translate('Đã hoàn thành'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryTile(
                Icons.hourglass_empty,
                '$pending',
                translate('Chưa hoàn thành'),
              ),
              const SizedBox(width: 12),
              _summaryTile(
                Icons.percent,
                '$rate%',
                translate('Tỉ lệ hoàn thành'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(translate('Hoàn thành 7 ngày qua')),
                _buildBarChart(days),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(translate('Theo phân loại')),
                for (final category in _categories)
                  _buildCategoryRow(category, tasks),
              ],
            ),
          ),
        ],
      ),
    );
  }
}