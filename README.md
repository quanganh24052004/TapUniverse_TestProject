# TestProject (Canvas & Photo Manager)

TestProject là một ứng dụng iOS được thiết kế để quản lý các dự án sáng tạo nghệ thuật. Ứng dụng cho phép người dùng tạo các dự án mới, thêm hình ảnh vào một không gian làm việc (Canvas) cố định, và cung cấp các công cụ tương tác trực quan (kéo thả, thu phóng, xoay, chỉnh độ mờ) để thao tác với ảnh. Cuối cùng, người dùng có thể kết xuất (export) Canvas thành một bức ảnh chất lượng cao để chia sẻ.

## 🚀 Tính năng nổi bật
- **Quản lý Dự án:** Tạo, xem danh sách và xóa dự án.
- **Không gian Canvas 1024x1024:** Một khu vực thiết kế chuẩn hóa, hiển thị đồng nhất trên mọi thiết bị.
- **Tương tác Đa điểm (Multi-touch):** 
  - Kéo thả di chuyển (Pan)
  - Phóng to/Thu nhỏ (Pinch)
  - Xoay hình ảnh (Rotation) bằng cử chỉ hai ngón tay.
- **Thanh công cụ Tùy chỉnh:** Nổi bật với thanh điều chỉnh độ mờ (Opacity Slider) linh hoạt.
- **Export Siêu Nét:** Kết xuất Canvas thành ảnh JPEG ở độ phân giải 3x (Super Retina) và chia sẻ qua Share Sheet của iOS.
- **Offline-First Data Flow:** Tự động lưu dự án xuống bộ nhớ cục bộ (`UserDefaults`) trước, giúp ứng dụng không bị phụ thuộc vào độ trễ của mạng. Tự động đồng bộ ngầm lên Server sau đó.

## 🏗 Kiến trúc & Mẫu thiết kế (Architecture & Design Patterns)
Dự án tuân thủ chặt গঠন kiến trúc **MVVM (Model - View - ViewModel)** kết hợp với **Repository Pattern**:
- **Model:** Các cấu trúc dữ liệu cơ bản (`Project`, `ProjectDetail`, `PhotoFrame`) với tính năng định tuyến phiên bản bằng thuộc tính `updatedAt`.
- **View:** Được xây dựng bằng SwiftUI. Tuy nhiên, phần lõi tương tác hình ảnh (`InteractiveCanvasView`) được viết bằng UIKit (`UIViewRepresentable`) để đảm bảo hiệu năng tối đa cho các cử chỉ phức tạp.
- **ViewModel:** Quản lý luồng trạng thái (`@Published`). Đảm bảo an toàn luồng (Thread-safety) tuyệt đối nhờ việc sử dụng annotation `@MainActor`.
- **Repository (`LocalProjectRepository`):** Lớp trừu tượng độc lập để giao tiếp với bộ nhớ cục bộ, tách rời hoàn toàn logic giải mã JSON ra khỏi ViewModel.

## 🛠 Công nghệ sử dụng (Tech Stack)
- **Ngôn ngữ:** Swift 5.8+ (áp dụng triệt để các tính năng mới như shorthand `if let`, mệnh đề `for...where`).
- **Giao diện:** SwiftUI & UIKit.
- **Bất đồng bộ:** Swift Concurrency (`async/await`, `Task`) và Combine (`.debounce` cho Auto-save).
- **Mạng (Network):** `URLSession` qua `NetworkManager`.
- **Đồ họa:** `UIGraphicsImageRenderer` cho tính năng render Canvas.
- **Unit Test:** `XCTest` (bao gồm các test case kiểm thử Auto-save, Export, và Xử lý lỗi dữ liệu).

## 📂 Cấu trúc thư mục (Project Structure)
```
TestProject/
├── Model/               # Định nghĩa dữ liệu (Project, ProjectDetail, PhotoFrame)
├── View/                # Các thành phần giao diện (SwiftUI & UIKit Wrappers)
├── ViewModel/           # Xử lý logic và trạng thái (ProjectListViewModel, ProjectDetailViewModel)
├── Repository/          # Kho chứa logic truy xuất dữ liệu cục bộ (LocalProjectRepository)
├── Network/             # Xử lý gọi API (NetworkManager)
├── Utils/               # Các công cụ hỗ trợ (CanvasRenderer, ImageCacheManager)
└── Extension/           # Chứa các thành phần con phục vụ View (PhotoContainerView)
```

## 🔥 Các tối ưu hoá đáng chú ý (Recent Optimizations)
1. **UX Không độ trễ (Zero-latency UX):** Xóa bỏ màn hình chờ loading khi thoát dự án; sử dụng hàm `prepareForExit()` để lưu cục bộ tức thì và xử lý đồng bộ API trong luồng ngầm (Background Task).
2. **Khắc phục Race Condition:** Sử dụng `updatedAt` để trộn (merge) danh sách từ API và Local Storage, đảm bảo dữ liệu mới nhất luôn được ưu tiên hiển thị.
3. **Độ nét ảnh xuất ra:** Nâng thông số `format.scale = 3.0` trong `CanvasRenderer`, giúp ảnh export nét gấp 3 lần kích thước hiển thị vật lý trên màn hình.
4. **Strict Concurrency (An toàn luồng):** Sửa lỗi biên dịch liên quan đến truyền singleton `shared` trong tham số mặc định của hàm `init` đối với các ViewModel dùng `@MainActor`.
5. **Clean Code & Conventions:** Tinh giản code với `typealias`, bảo mật thuộc tính với `private(set)`, tái cấu trúc hàm khởi tạo memberwise vào các `extension`.

## ⚙️ Hướng dẫn cài đặt (How to run)
1. Yêu cầu hệ thống: Xcode 15 trở lên, iOS 16.0+.
2. Mở file `TestProject.xcodeproj`.
3. Nhấn tổ hợp phím `Command + B` để Build dự án.
4. Chọn Simulator (khuyên dùng iPhone 15 Pro/16 Pro) và nhấn `Command + R` để chạy ứng dụng.
5. Để kiểm thử luồng Offline-First, hãy thử thêm một bức ảnh, di chuyển nó và thoát ra (nhấn Back) thật nhanh để xem ứng dụng lưu lại trạng thái lập tức.
