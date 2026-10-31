import 'package:flutter/material.dart';
import 'package:todoapp/theme/app_colors.dart';

/// Các màn hình chính của app. Thứ tự khớp với IndexedStack trong HomePage.
enum AppTab { shop, inventory, schedule, focus, stats, account }

/// Thanh điều hướng dưới: 2 mục bên trái, nút giữa nổi, 2 mục bên phải.
class MainBottomBar extends StatelessWidget {
  final AppTab current;
  final bool pickerOpen;
  final AppColorTheme colorTheme;
  final String Function(String) translate;
  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback onCenterTap;

  const MainBottomBar({
    super.key,
    required this.current,
    required this.pickerOpen,
    required this.colorTheme,
    required this.translate,
    required this.onTabSelected,
    required this.onCenterTap,
  });

  static const double _barHeight = 64;
  static const double _overlap = 20; // phần nút giữa nhô lên khỏi thanh
  static const double _centerSize = 64;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isFocus = current == AppTab.focus;
    final centerIcon = isFocus ? Icons.album : Icons.event_note;
    final centerLabel = isFocus ? 'Tập trung' : 'Đặt lịch';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _barHeight + _overlap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // nền thanh
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: colorTheme.dark.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _BarItem(
                          icon: Icons.storefront_outlined,
                          activeIcon: Icons.storefront,
                          label: translate('Cửa hàng'),
                          selected: current == AppTab.shop,
                          colorTheme: colorTheme,
                          onTap: () => onTabSelected(AppTab.shop),
                        ),
                      ),
                      Expanded(
                        child: _BarItem(
                          icon: Icons.inventory_2_outlined,
                          activeIcon: Icons.inventory_2,
                          label: translate('Kho'),
                          selected: current == AppTab.inventory,
                          colorTheme: colorTheme,
                          onTap: () => onTabSelected(AppTab.inventory),
                        ),
                      ),
                      // chỗ trống dành cho nút giữa + nhãn chế độ hiện tại
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              translate(centerLabel),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorTheme.dark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _BarItem(
                          icon: Icons.bar_chart_outlined,
                          activeIcon: Icons.bar_chart,
                          label: translate('Thống kê'),
                          selected: current == AppTab.stats,
                          colorTheme: colorTheme,
                          onTap: () => onTabSelected(AppTab.stats),
                        ),
                      ),
                      Expanded(
                        child: _BarItem(
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          label: translate('Tài khoản'),
                          selected: current == AppTab.account,
                          colorTheme: colorTheme,
                          onTap: () => onTabSelected(AppTab.account),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // nút giữa nổi lên
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedScale(
                    scale: pickerOpen ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: Material(
                      color: colorTheme.dark,
                      elevation: 6,
                      shadowColor: colorTheme.dark.withValues(alpha: 0.5),
                      shape: const CircleBorder(
                        side: BorderSide(color: Colors.white, width: 4),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onCenterTap,
                        child: SizedBox(
                          width: _centerSize,
                          height: _centerSize,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              pickerOpen ? Icons.close : centerIcon,
                              key: ValueKey<bool>(pickerOpen),
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // vùng an toàn phía dưới (điện thoại có thanh cử chỉ)
        ColoredBox(
          color: Colors.white,
          child: SizedBox(height: bottomInset, width: double.infinity),
        ),
      ],
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final AppColorTheme colorTheme;
  final VoidCallback onTap;

  const _BarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.colorTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? colorTheme.dark : Colors.grey[600];
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 30,
            decoration: BoxDecoration(
              color: selected
                  ? colorTheme.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(selected ? activeIcon : icon, color: color, size: 24),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lớp phủ hiện ra khi bấm nút giữa: hai bong bóng chọn Đặt lịch / Tập trung.
class ModePickerOverlay extends StatelessWidget {
  final bool open;
  final AppTab current;
  final AppColorTheme colorTheme;
  final String Function(String) translate;
  final ValueChanged<AppTab> onSelect;
  final VoidCallback onDismiss;

  const ModePickerOverlay({
    super.key,
    required this.open,
    required this.current,
    required this.colorTheme,
    required this.translate,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !open,
      child: AnimatedOpacity(
        opacity: open ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDismiss,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ModeBubble(
                      icon: Icons.event_note,
                      label: translate('Đặt lịch'),
                      selected: current == AppTab.schedule,
                      open: open,
                      colorTheme: colorTheme,
                      onTap: () => onSelect(AppTab.schedule),
                    ),
                    const SizedBox(width: 36),
                    _ModeBubble(
                      icon: Icons.album,
                      label: translate('Tập trung'),
                      selected: current == AppTab.focus,
                      open: open,
                      colorTheme: colorTheme,
                      onTap: () => onSelect(AppTab.focus),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool open;
  final AppColorTheme colorTheme;
  final VoidCallback onTap;

  const _ModeBubble({
    required this.icon,
    required this.label,
    required this.selected,
    required this.open,
    required this.colorTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: open ? Offset.zero : const Offset(0, 0.6),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: selected ? colorTheme.dark : Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 32,
                color: selected ? Colors.white : colorTheme.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}