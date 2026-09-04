# Brainstorm: Desktop app phát âm thanh + nhận mic cho phần thi speaking

**Date:** 2026-08-24

## Ideas Explored

- **Implement từ đầu** — bị loại ngay sau khi scout: `record: ^6.2.1` (mic) và `just_audio: ^0.10.6` (playback) đã có sẵn trong `pubspec.yaml`, đã wire đầy đủ qua `AudioRecorderService`/`AudioPlayerService` + `AutoRecordCubit` cho cả 8 màn hình speaking, kèm auto upload + offline sync (`PendingMediaUploadDao`, `MediaUploadCoordinator`, `SyncEngine`).
- **Volume/amplitude meter real-time** — user muốn tính năng này nhưng `AudioRecorderService` hiện chỉ expose `start/stop/isRecording`, không có amplitude stream. Ghi nhận là gap thật, nhưng ngoài scope lần brainstorm này (đã chốt focus là verify build/permission trước).
- **GitHub Actions build matrix (windows/macos/ubuntu-latest)** — cân nhắc làm CI để verify build tự động trên cả 3 OS. Repo `pte-org/pte-app` đã có remote GitHub, chưa có `.github/workflows`. Bị hoãn: user chốt "chưa, chỉ fix bug trước".
- **Test tay trên máy macOS/Linux thật** (mượn đồng đội / cloud Mac) — cách duy nhất verify chắc chắn TCC permission prompt + ghi âm hoạt động thật trên macOS. Bị hoãn: user hiện chỉ có máy Windows, không có đồng đội macOS/Linux để nhờ ngay.
- **Test trực tiếp trên Windows (máy hiện tại)** — được chọn: zero cost, verify được ngay flow ghi âm/phát audio thật trên platform duy nhất user có quyền truy cập.
- **Fix lỗ hổng macOS đã phát hiện khi scout** — được chọn: `macos/Runner/Info.plist` thiếu `NSMicrophoneUsageDescription`, và `DebugProfile.entitlements`/`Release.entitlements` bật `com.apple.security.app-sandbox` nhưng thiếu `com.apple.security.device.audio-input` → sẽ chặn cứng quyền mic khi build macOS sandboxed. Sửa trước khi có máy thật để test, thay vì chờ phát hiện qua lỗi runtime.

## User's Direction

User ban đầu tưởng cần implement từ đầu, nhưng thực tế câu hỏi đúng là: "code hiện tại đã chạy được trên cả 3 platform chưa?" — vì user chỉ có máy Windows, chưa test được macOS/Linux. Hướng chốt: verify ở mức "build + xin quyền mic hoạt động" (không cần tới toàn bộ luồng auto-record/upload lần này), giới hạn ở phần **fix bug macOS đã biết + test tay trên Windows**. CI và test tay macOS/Linux thật để cho vòng sau khi có điều kiện (đồng đội/cloud Mac).

## Open Questions

- Ai/khi nào sẽ có quyền truy cập máy macOS/Linux thật để đóng vòng verify permission (test tay hoặc mượn đồng đội)?
- Volume/amplitude meter real-time cho mic — làm ở lần cook riêng sau, cần spec riêng (không nằm trong spec này).
- CI (GitHub Actions build matrix) — hoãn, nhưng nên nhắc lại khi nào project cần tự động hoá verify build 3 platform.

## Risks

- **macOS mic permission chưa test runtime thật** — dù đã fix Info.plist/entitlements theo tài liệu Apple, không có gì đảm bảo 100% cho tới khi chạy trên máy macOS thật (build sandbox có thể có thêm ràng buộc khác).
- **Linux chưa được xem xét kỹ trong lần scout này** — record_linux (PipeWire) không cần permission dialog như macOS, nhưng cũng chưa được verify build/runtime thật trong session này.
- **Fix macOS "mù"** — sửa Info.plist/entitlements dựa trên tài liệu chuẩn nhưng chưa build-verify trên máy macOS thật, có thể còn thiếu key khác nếu Apple thay đổi yêu cầu.
