# 📝 Việc Cần Làm

Ứng dụng quản lý công việc cá nhân viết bằng **Flutter**: ghi lại việc cần làm, đánh dấu hoàn thành, theo dõi tiến độ và tập trung làm việc với bộ đếm giờ kèm nhạc nền. Dữ liệu được lưu trên máy và tự đồng bộ lên đám mây, nên đăng nhập trên thiết bị khác vẫn thấy đủ công việc của mình.

## 👥 Thành viên thực hiện

| Họ tên | Mã sinh viên | Vai trò |
| :--- | :---: | :--- |
| Lê Văn Tuấn | 23010330 | Trưởng nhóm |
| Trần Quang Huy | 24100425 | Thành viên |

## ✨ Tính năng chính

- **Tài khoản:** đăng ký, đăng nhập bằng tên đăng nhập và mật khẩu hoặc bằng Google/Facebook, quên mật khẩu (gửi email đặt lại, có che bớt địa chỉ email).
- **Quản lý công việc:** thêm, sửa, xóa (có hoàn tác), đánh dấu hoàn thành, chọn ngày thực hiện, phân loại theo Ngày / Tuần / Tháng / Năm và tìm kiếm theo tên.
- **Lịch sử:** xem lại các việc đã hoàn thành, hoàn tác hoặc xóa khỏi lịch sử.
- **Thống kê:** tổng số việc, đã xong, chưa xong, tỉ lệ hoàn thành, tiến độ từng phân loại và biểu đồ theo ngày.
- **Tập trung:** đếm giờ 30 / 60 / 90 / 120 phút, tạm dừng và tiếp tục, phát nhạc nền (lofi) trên đĩa than quay, nhớ lựa chọn âm thanh của từng tài khoản.
- **Đồng bộ đám mây:** dữ liệu lưu trên máy bằng Hive, tự đẩy lên Firestore sau khi thay đổi; mất mạng vẫn dùng bình thường.
- **Cá nhân hóa:** đổi màu chủ đề, chuyển tiếng Việt / tiếng Anh, đổi ảnh đại diện.

## 🛠 Công nghệ sử dụng

| Thành phần | Công nghệ |
| :--- | :--- |
| Giao diện, ngôn ngữ | Flutter (Material 3), Dart |
| Lưu trữ trên máy | Hive (`hive_flutter`) |
| Xác thực | Firebase Authentication |
| Cơ sở dữ liệu đám mây | Cloud Firestore |
| Âm thanh | audioplayers |
| Kiểm thử | flutter_test |

## 🚀 Chạy thử

```bash
flutter pub get
flutter run -d chrome
```

Chạy bộ kiểm thử:

```bash
flutter test
```

<!-- Chèn ảnh chụp màn hình ứng dụng ở đây -->e.
