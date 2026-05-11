# MoneyMate Student

## 1. Tên đề tài

Xây dựng ứng dụng quản lý chi tiêu cá nhân cho sinh viên bằng Flutter, sử dụng Firebase Firestore và ExchangeRate-API.

## 2. Mô tả dự án

MoneyMate Student là ứng dụng di động hỗ trợ sinh viên ghi chép và quản lý các khoản thu chi cá nhân hằng ngày. Ứng dụng cho phép người dùng đăng ký, đăng nhập, thêm khoản thu, thêm khoản chi, xem danh sách giao dịch, thống kê tổng thu, tổng chi và số dư.

Ứng dụng sử dụng Firebase Authentication để quản lý tài khoản, Cloud Firestore để lưu trữ dữ liệu trên cơ sở dữ liệu đám mây và ExchangeRate-API để chuyển đổi tiền tệ.

## 3. Công nghệ sử dụng

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- ExchangeRate-API
- HTTP
- Intl

## 4. Chức năng chính

- Đăng ký tài khoản
- Đăng nhập
- Đăng xuất
- Thêm khoản thu
- Thêm khoản chi
- Hiển thị danh sách giao dịch
- Sửa giao dịch
- Xóa giao dịch
- Thống kê tổng thu, tổng chi, số dư
- Chuyển đổi tiền tệ bằng API bên thứ ba

## 5. Lộ trình 10 ngày

- Ngày 1: Setup môi trường, tạo project Flutter, tạo giao diện khởi đầu
- Ngày 2: Kết nối Firebase với Flutter
- Ngày 3: Làm giao diện đăng nhập, đăng ký
- Ngày 4: Xử lý đăng nhập, đăng ký bằng Firebase Authentication
- Ngày 5: Tạo model giao dịch và form thêm giao dịch
- Ngày 6: Lưu và đọc giao dịch từ Cloud Firestore
- Ngày 7: Sửa, xóa giao dịch và thống kê thu chi
- Ngày 8: Tích hợp ExchangeRate-API
- Ngày 9: Làm đẹp giao diện, validation và xử lý lỗi
- Ngày 10: Test trên điện thoại thật, build APK và hoàn thiện demo