# TapUniverse Canvas Editor 🎨

Đây là dự án Editor hình ảnh kết hợp sức mạnh giao diện hiện đại của **SwiftUI** và khả năng tương tác đồ họa linh hoạt, mạnh mẽ của **UIKit**. Ứng dụng cho phép người dùng ghép, di chuyển, thu phóng và tinh chỉnh độ mờ của nhiều hình ảnh trên cùng một không gian Canvas.

## Tính năng Nổi bật ✨

- **Tương tác đa điểm mượt mà (Gestures):** Sử dụng `UIGestureRecognizer` của UIKit để quản lý cực kỳ chính xác các thao tác Kéo (Pan), Phóng to/Thu nhỏ (Pinch), và Xoay (Rotation). Đặc biệt, hệ thống "gác cổng" thông minh sẽ nhường quyền điều khiển Touch cho nền (Scroll) khi bức ảnh chưa được chọn.
- **Tự động lưu (Auto-Save) & Offline First:** Trạng thái toạ độ, góc xoay và độ mờ của từng bức ảnh được lưu trữ tự động sau mỗi **1 giây** (cơ chế Debounce) xuống bộ nhớ đệm `UserDefaults` cục bộ. Dù mất kết nối mạng hay vô tình tắt app, 100% tiến trình vẫn được phục hồi khi mở lại.
- **Khung Canvas tương tác vô cực:** Bức vẽ (Canvas) được bao bọc bởi `UIScrollView` cho phép người dùng cuộn không giới hạn ra mọi phía hoặc thu phóng tổng thể khu vực làm việc.
- **Kết xuất đồ hoạ thông minh (Smart Export):** Không chỉ chụp ảnh màn hình đơn thuần, ứng dụng sẽ tự động dùng thuật toán đo đạc **Bounding Box** của toàn bộ các ảnh, sau đó cắt (Crop) khung hình vừa khít với lề để tối ưu hóa bố cục và dung lượng ảnh xuất ra.

## Kiến trúc Hệ thống 🏛️

Dự án áp dụng mô hình kiến trúc **MVVM (Model - View - ViewModel)** kết hợp với **Coordinator Pattern** để làm cầu nối giữa SwiftUI và UIKit:

1. **Models:** 
   - `PhotoFrame`: Lưu trữ cấu trúc toạ độ `FrameRect`, ID, URL, góc xoay, và độ mờ. Hỗ trợ chuẩn `Codable` và `Equatable` tối ưu.
2. **ViewModels:** 
   - Xử lý các logic nghiệp vụ (Network API, Local Storage, State Auto-save) hoàn toàn độc lập với UI. Tương thích Strict Concurrency (Swift 6) với `@MainActor`.
3. **Views (SwiftUI):**
   - Đảm nhiệm bố cục tổng thể (`ProjectListView`, `ProjectDetailView`, `CustomOpacitySlider`).
4. **UIKit Interoperability:** 
   - `InteractiveCanvasView`: Dùng `UIViewRepresentable` bọc lại một `UIScrollView` và quản lý hàng loạt các `PhotoContainerView` bên trong thông qua `Coordinator`.
5. **Utils (Tối ưu hóa):**
   - `ImageCacheManager`: Trạm trung chuyển bộ nhớ đệm (RAM) sử dụng `NSCache` để tránh load lại ảnh lặp lại, tiết kiệm tài nguyên.
   - `CanvasRenderer`: Bộ công cụ xử lý đồ họa `UIGraphicsImageRenderer` chuyên trách xuất file JPEG từ danh sách toạ độ ảnh.

## Báo cáo Tối ưu hoá Gần đây 🚀

Dự án vừa trải qua một đợt nâng cấp động cơ cốt lõi:
- **Zero-Latency Rendering:** Áp dụng `Equatable` để loại bỏ vòng lặp cập nhật giao diện (O(n)) thừa thãi. Hệ thống chỉ phân bổ lại đồ hoạ cho bức ảnh nào thực sự đang bị thay đổi tọa độ bởi người dùng.
- **Memory Management:** Loại bỏ tình trạng rò rỉ và quá tải RAM khi load ảnh độ phân giải cao nhờ `ImageCacheManager`.
- **UX Scroll Fix:** Khắc phục triệt để lỗi "nuốt Touch" của bộ nhận diện cử chỉ, giúp thao tác vuốt trượt màn hình mượt mà như native scroll.
- **Clean Code & Constants:** Chuẩn hoá các hardcode String, keys và tham số vào file `AppConstants.swift`. Chuẩn hoá 100% tài liệu theo định dạng Apple Docstrings (`///`).

## Hướng dẫn Chạy (Run) và Kiểm thử (Testing) 🛠️

1. Mở file `TestProject.xcodeproj` bằng Xcode.
2. Ứng dụng không yêu cầu dependency bên ngoài (Không cần CocoaPods/SPM phức tạp). Bấm `Cmd + R` để chạy thẳng trên Simulator hoặc thiết bị thật.
3. Để kiểm tra sự bền vững của dữ liệu, bạn có thể chạy bộ Tests `Cmd + U` để thực thi `ProjectListViewModelTests` và `ProjectDetailViewModelTests` (đảm bảo tính năng Offline Load và Auto-save hoạt động đúng cơ chế ưu tiên).

---

*Phát triển và bảo trì bởi Quang Anh (TapUniverse).*
