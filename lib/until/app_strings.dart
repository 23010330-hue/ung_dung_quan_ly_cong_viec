/// Bảng dịch tiếng Việt -> tiếng Anh dùng chung cho cả app.
/// Khóa là câu tiếng Việt; không có bản dịch thì giữ nguyên chữ.
const Map<String, String> _english = {
  // Danh sách việc
  'Việc Cần Làm': 'To-Do List',
  'Ngày': 'Daily',
  'Tuần': 'Weekly',
  'Tháng': 'Monthly',
  'Năm': 'Yearly',
  'Tất cả': 'All',
  'Bỏ xem lịch sử': 'Clear Date Filter',
  'Xem lịch sử theo ngày': 'Select Date',
  'Đang xem công việc của ngày:': 'Viewing tasks for date:',
  'Đang xem công việc của hôm nay:': "Viewing today's tasks:",
  'Đang xem tất cả việc chưa hoàn thành:': 'Viewing all incomplete tasks:',
  'Thêm Công Việc': 'Add Task',
  'Sửa công việc': 'Edit Task',
  'Phân Loại:': 'Category:',
  'Ngày thực hiện:': 'Scheduled date:',
  'Chọn ngày ghi chú': 'Pick note date',
  'Lưu': 'Save',
  'Hủy': 'Cancel',
  'Đã xóa công việc': 'Task deleted',
  'Hoàn tác': 'Undo',
  'Chưa có việc nào': 'Nothing to do yet',
  'Bấm + để thêm công việc mới': 'Tap + to add a new task',
  // Tìm kiếm
  'Tìm kiếm': 'Search',
  'Tìm công việc...': 'Search tasks...',
  'Đóng tìm kiếm': 'Close search',
  'Kết quả tìm kiếm cho:': 'Search results for:',
  'Không tìm thấy việc nào': 'No tasks found',
  'Thử từ khóa khác': 'Try a different keyword',
  // Lịch sử
  'Lịch sử công việc': 'Task History',
  'Hoàn thành:': 'Completed:',
  'Kế hoạch:': 'Scheduled:',
  'Chưa có công việc đã hoàn thành': 'No completed tasks yet',
  'Xem lịch sử hoàn thành': 'View completed history',
  // Thống kê
  'Thống kê': 'Statistics',
  'Tổng số việc': 'Total tasks',
  'Đã hoàn thành': 'Completed',
  'Chưa hoàn thành': 'Pending',
  'Tỉ lệ hoàn thành': 'Completion rate',
  'Hoàn thành 7 ngày qua': 'Completed in the last 7 days',
  'Theo phân loại': 'By category',
  // Thanh điều hướng
  'Cửa hàng': 'Shop',
  'Kho': 'Inventory',
  'Tài khoản': 'Account',
  'Đặt lịch': 'Schedule',
  'Tập trung': 'Focus',
  // Trang chờ
  'Cửa hàng âm thanh': 'Sound Shop',
  'Kho của tôi': 'My Inventory',
  'Chế độ tập trung': 'Focus Mode',
  'Sắp ra mắt': 'Coming soon',
  'Cửa hàng âm thanh sẽ mở ở bước tiếp theo.':
      'The sound shop will open in the next step.',
  'Nơi cất các âm thanh bạn đã mua sẽ ở đây.':
      'The sounds you have bought will be kept here.',
  'Máy đĩa than tập trung đang được chế tạo.':
      'The focus record player is under construction.',
  // Tài khoản
  'Ảnh đại diện': 'Profile picture',
  'Chọn ảnh mới': 'Choose a new photo',
  'Xóa ảnh đại diện': 'Remove profile picture',
  'Không thể chọn ảnh này': 'Could not pick this photo',
  'Giao diện': 'Appearance',
  'Đổi màu giao diện': 'Change Theme Color',
  'Ngôn ngữ': 'Language',
  'Đăng xuất': 'Log out',
  'Bạn muốn đăng xuất khỏi tài khoản?': 'Log out of your account?',
  // Chế độ tập trung
  'Bắt đầu': 'Start',
  'Tạm dừng': 'Pause',
  'Tiếp tục': 'Resume',
  'Kết thúc': 'Finish',
  'phút': 'min',
  'Sẵn sàng': 'Ready',
  'Đang tập trung': 'Focusing',
  'Đã tạm dừng': 'Paused',
  'Hoàn thành!': 'Done!',
  'Bạn đã tập trung xong. Làm tốt lắm!': 'You finished your session. Well done!',
  'Xong': 'OK',
  'Kết thúc phiên tập trung?': 'End this focus session?',
  'Thời gian đã chạy sẽ không được tính.': 'The time so far will not count.',
  'Đã tạm dừng vì bạn rời khỏi app': 'Paused because you left the app',
  'Nếu rời khỏi app, đồng hồ sẽ tạm dừng. Quay lại trong 1 phút thì tự chạy tiếp.':
      'If you leave the app, the timer pauses. Come back within 1 minute and it resumes by itself.',
  // Chọn đĩa nhạc
  'Chọn âm thanh': 'Choose a sound',
  'Chạm vào đĩa để nghe thử. Nhạc phát khi bạn bắt đầu tập trung.':
      'Tap a record to preview it. It plays when you start focusing.',
  'Đĩa mới sẽ có ở Cửa hàng âm thanh.': 'New records will arrive in the Sound Shop.',
  // Coin
  'Bạn còn đó không?': 'Are you still there?',
  'Đồng hồ đã tạm dừng để kiểm tra. Bấm nút để tập trung tiếp.':
      'The timer paused to check on you. Tap the button to keep focusing.',
  'Tôi còn đây': "I'm here",
  'Hôm nay bạn đã nhận đủ coin từ tập trung.':
      "You've earned all your focus coins for today.",
  'Chỉ nhận một phần vì chạm giới hạn hôm nay.':
      "Only part counted because you hit today's limit.",
  'Coin của tôi': 'My coins',
  'Hôm nay': 'Today',
  'Cách kiếm coin': 'How to earn coins',
  'Lịch sử coin': 'Coin history',
  'Chưa có giao dịch coin nào': 'No coin activity yet',
  'Phiên tập trung': 'Focus session',
  'Việc đúng hạn': 'On-time task',
  'việc': 'task',
  // Cửa hàng và Kho
  'Chạm vào đĩa để nghe thử và mua bằng coin.': 'Tap a record to preview it and buy it with coins.',
  'Chạm vào đĩa để dùng cho phiên tập trung.': 'Tap a record to use it for focus sessions.',
  'Mua': 'Buy',
  'Mua đĩa': 'Bought record',
  'Nghe thử': 'Preview',
  'Dừng': 'Stop',
  'Đã sở hữu': 'Owned',
  'Đã có trong Kho': 'In your inventory',
  'Đang dùng': 'In use',
  'Cần thêm': 'Need',
  'Chưa đủ coin': 'Not enough coins',
  'Đang tập trung nên chưa nghe thử được.': "Can't preview during a focus session.",
  // Tên đĩa
  'Lofi đĩa than': 'Lofi vinyl',
  'Mưa rơi': 'Rain',
  'Sóng biển': 'Ocean waves',
  'Tiếng ồn nâu': 'Brown noise',
  'Lửa trại': 'Campfire',
  'Không phát nhạc': 'No sound',
};

String translateText(String text, bool isVietnamese) {
  if (isVietnamese) return text;
  return _english[text] ?? text;
}