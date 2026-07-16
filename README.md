<!-- ## Cookflow - Quản lý công thức nấu ăn
# Tổng quát

Cookflow là ứng dụng di động hỗ trợ người dùng thực hiện các công thức nấu ăn theo từng bước một cách trực quan và dễ theo dõi. Thay vì trình bày công thức dưới dạng văn bản liên tục như sách dạy nấu ăn hoặc các ứng dụng truyền thống, Cookflow tổ chức mỗi công thức thành một quy trình gồm nhiều bước thực hiện được liên kết với nhau. Mỗi bước có thể là bước hướng dẫn thông thường hoặc bước yêu cầu đếm thời gian. Trong quá trình thực hiện, ứng dụng sẽ hướng dẫn người dùng lần lượt theo từng bước và hỗ trợ bộ đếm thời gian đối với các công đoạn như hầm, hấp, luộc hoặc nướng. Điều này giúp giảm thao tác thủ công, hạn chế quên thời gian và mang lại trải nghiệm nấu ăn thuận tiện hơn.

**Project Name:** Cookflow
**Nền tảng:** Mobile App

---
# Phân tích và công nghệ

## Phân tích chuyên sâu

Phần lớn các ứng dụng hướng dẫn nấu ăn hiện nay chỉ hiển thị công thức dưới dạng danh sách các bước hoặc văn bản liên tục. Người dùng vẫn phải tự theo dõi tiến độ thực hiện cũng như sử dụng đồng hồ hẹn giờ bên ngoài đối với các công đoạn cần thời gian.

Cookflow tiếp cận công thức theo mô hình Workflow. Mỗi công thức được xây dựng từ nhiều Step liên kết với nhau tạo thành một quy trình hoàn chỉnh. Mỗi Step được quản lý độc lập, cho phép thay đổi nội dung, thứ tự hoặc loại bước mà ==không ảnh hưởng== đến toàn bộ công thức.

> Trong phiên bản đầu, hệ thống hỗ trợ hai loại Step:
> - **Static Step:** Bước hướng dẫn thông thường, người dùng hoàn thành và chọn **Tiếp tục** để sang bước kế tiếp.
> - **Timer Step:** Bước yêu cầu thực hiện trong một khoảng thời gian xác định, hệ thống hiển thị bộ đếm ngược và hỗ trợ người dùng theo dõi thời gian chế biến.

---
## Mô hình CMS

CookFlow áp dụng mô hình **Content Management System (CMS)** nhằm hỗ trợ người dùng quản lý nội dung của các công thức nấu ăn một cách linh hoạt. Thay vì lưu toàn bộ hướng dẫn dưới dạng một đoạn văn bản, hệ thống chia công thức thành nhiều thành phần dữ liệu độc lập như thông tin món ăn, nguyên liệu và các bước thực hiện. Cách tổ chức này giúp việc cập nhật, chỉnh sửa hoặc mở rộng nội dung trở nên dễ dàng hơn mà không ảnh hưởng đến toàn bộ công thức.

Workflow được xây dựng từ nhiều **Step** liên kết với nhau theo trình tự thực hiện. Trong phiên bản đầu, hệ thống hỗ trợ hai loại Step là **Static Step** và **Timer Step**, đồng thời cho phép mở rộng thêm các loại Step khác trong tương lai.

---
## Công nghệ

Ứng dụng được phát triển trên nền tảng **Flutter**, cho phép triển khai trên Android từ một mã nguồn. Dữ liệu công thức, quy trình thực hiện và các thông tin của người dùng được lưu trữ cục bộ bằng **Hive**, giúp ứng dụng hoạt động ổn định mà không phụ thuộc vào kết nối Internet. Ngoài ra, ứng dụng tích hợp **Flutter Local Notifications** để hỗ trợ thông báo khi các bước hẹn giờ hoàn thành.

---
# Chức năng
## 1. Quản lý công thức

#### Hệ thống cho phép người dùng ==tạo== và ==quản lý== các công thức nấu ăn.
Thông tin của một công thức bao gồm:
- Tên món ăn.
- Mô tả.
- Danh sách nguyên liệu.
- Hình ảnh minh họa.
- Thông tin bổ sung nếu cần.
Mỗi công thức bao gồm một quy trình thực hiện được tạo thành từ nhiều Step liên kết với nhau.

---
## 2. Quản lý quy trình thực hiện

#### Mỗi công thức được xây dựng từ nhiều Step.
Hệ thống hỗ trợ:
- Thêm Step mới.
- Chỉnh sửa nội dung Step.
- Xóa Step.
- Thay đổi thứ tự thực hiện.
- Liên kết các Step để tạo thành Workflow.
#### Mỗi Step lưu trữ các thông tin như:
- Tên bước.
- Nội dung hướng dẫn.
- Loại Step.
- Thời gian thực hiện (đối với Timer Step).
- Hình ảnh minh họa (nếu có).
---
## 3. Thực hiện công thức

#### Khi người dùng lựa chọn một công thức, hệ thống sẽ thực hiện theo đúng Workflow đã được thiết lập.
Đối với ==Static Step==:
- Hiển thị nội dung hướng dẫn.
- Người dùng chọn **Tiếp tục** để chuyển sang bước kế tiếp.
Đối với ==Timer Step==:
- Hiển thị thời gian đếm ngược.
- Hỗ trợ theo dõi thời gian thực hiện.
- Thông báo khi thời gian kết thúc.
- Cho phép chuyển sang bước tiếp theo.
Sau khi hoàn thành toàn bộ các Step, hệ thống ==thông báo== công thức đã hoàn tất.

---
## 4. Quản lý thời gian

#### Hệ thống tích hợp ==bộ đếm thời gian trực tiếp== trong quy trình thực hiện.
Các chức năng bao gồm:
- Khởi động bộ đếm.
- Hiển thị thời gian còn lại.
- Thông báo khi hết thời gian.
- Chuyển sang bước tiếp theo sau khi Timer Step hoàn thành.
Việc tích hợp bộ đếm giúp người dùng không cần sử dụng ứng dụng hẹn giờ bên ngoài.

--- -->