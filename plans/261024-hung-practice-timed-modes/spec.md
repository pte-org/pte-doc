# Spec: Practice có chế độ tính giờ / không tính giờ và trình ghi âm có sóng âm

**Ngày:** 2026-10-24
**Owner:** Hung
**Repo bị ảnh hưởng:** `pte-practice` (chính), `pte-api` (module `practice`)
**Phụ thuộc:** làm tiếp trên nhánh `hung/feat/practice-password-login` (đăng nhập bằng tài khoản trung tâm cấp, V132). Migration mới của spec này bắt đầu từ **V133**.
**Trạng thái:** Chờ duyệt

Quy ước trong tài liệu: **[Đã chốt]** là điều Hung đã quyết trong buổi brainstorm; **[Quyết định của Claude]** là lựa chọn mặc định mình đưa ra, Hung có thể đổi khi đọc.

---

## 1. Vì sao làm

`pte-practice` là app **luyện tập**, nhưng hiện chạy như một phiên thi thu nhỏ:

- Mỗi lần bấm "Start practice" tạo một phiên **chỉ có 1 câu** với đồng hồ chung **60:00** (`PRACTICE_TIME_LIMIT_SECONDS = 3600`), phải qua màn Overview rồi mới vào làm.
- Không có nhịp thời gian theo từng câu như thi PTE thật (nghe đề → chuẩn bị → trả lời), nên học viên không luyện được phản xạ thời gian.
- Ngược lại, người muốn luyện thong thả lại bị đồng hồ 60 phút đè lên.
- Trình ghi âm chỉ có "Start recording" và dòng "No recording yet": không nghe lại được bản ghi của mình, không ghi lại được, không thấy sóng âm.
- Backend luôn lấy **cùng một câu** cho mỗi dạng bài (`findPublishedPracticeQuestionIdsByTaskTypeKey` sắp theo `publicId`, `PageRequest.of(0, 1)`), nên luyện lại là gặp câu cũ.

Mục tiêu: học viên chọn được cách luyện phù hợp — **thi thử đúng nhịp** hoặc **luyện thong thả** — và nghe lại được giọng mình.

## 2. Mục tiêu, không làm, và những điều coi là thất bại

### Mục tiêu
1. Bấm vào một dạng bài → chọn **Tính giờ** hoặc **Không tính giờ** → vào làm ngay. **[Đã chốt]**
2. Bỏ đồng hồ chung 60 phút của phiên. **[Đã chốt]**
3. Chế độ tính giờ đi đúng nhịp thi: đề audio tự phát, đếm ngược chuẩn bị, tự bật ghi âm, hết giờ tự dừng. **[Đã chốt]**
4. Trình ghi âm: nghe lại bản ghi, ghi lại, có sóng âm của đoạn ghi. **[Đã chốt]**
5. Một phiên luyện gồm nhiều câu của cùng dạng bài, không lặp câu trong phiên, ưu tiên câu học viên chưa làm. **[Quyết định của Claude]** — cần thiết để chế độ tính giờ có ý nghĩa và để sửa lỗi "luôn cùng một câu".

### User stories

| ID | Ưu tiên | Story | Tiêu chí (§7) |
|---|---|---|---|
| US-1 | **P1** | Là học viên, khi bấm một dạng bài tôi chọn được *Tính giờ* hoặc *Không tính giờ* và số câu, rồi vào làm ngay, không bị đồng hồ 60 phút. | 1, 3 |
| US-2 | **P1** | Là học viên luyện thong thả, tôi ghi âm, nghe lại giọng mình và ghi lại cho tới khi hài lòng; bản nộp là bản cuối. | 5, 7 |
| US-3 | **P1** | Là học viên luyện thi, ở chế độ tính giờ tôi đi đúng nhịp: đề phát một lần, đếm ngược chuẩn bị, tự ghi âm, hết giờ tự dừng, không ghi lại. | 4 |
| US-4 | **P1** | Là học viên, một phiên cho tôi nhiều câu khác nhau, lần sau ưu tiên câu tôi chưa làm. | 2 |
| US-5 | **P2** | Là học viên, tôi thấy sóng âm khi đang ghi và sóng âm của bản ghi để tua khi nghe lại. | 6 |
| US-6 | **P2** | Là học viên Writing/Reading/Listening, chế độ tính giờ cho tôi đồng hồ theo từng câu; hết giờ thì khoá ô trả lời. | 3, 4 (phần không ghi âm) |
| US-7 | **P3** | Là học viên quay lại, hộp chọn nhớ chế độ và số câu tôi chọn lần trước cho từng dạng bài. | — (kiểm bằng tay) |
| US-8 | **P1** (kỹ thuật) | Là người phát triển, phiên cũ trước V133 vẫn mở được; UI dùng component chung theo §5.4. | 8, 9 |

### Không làm trong spec này
- Study-Pack (phiên trộn nhiều dạng bài) — để spec riêng; thiết kế ở đây không được chặn việc đó (request vẫn nhận nhiều `taskTypeCodes`).
- Thay đổi cách chấm điểm, AI scoring, trang Review, trang Progress.
- Bỏ hay đổi bước chọn mức tự tin (confidence) — giữ nguyên như hiện tại.
- Exam client `pte-app` và luồng thi của tổ chức: không đụng.
- Ép thời gian ở server (practice là luyện tập, đồng hồ do client giữ — xem §5.5).

### Những điều coi là thất bại dù code "chạy"
- Chế độ không tính giờ mà vẫn có bất kỳ đồng hồ đếm ngược hay hạn nộp nào.
- Chế độ tính giờ mà học viên ghi lại được câu nói, hoặc nghe đề nhiều lần.
- Ghi lại (re-record) mà bản ghi cũ vẫn là bản được nộp, hoặc bản ghi bị mất khi upload lỗi.
- Sóng âm là hình trang trí không phản ánh giọng thật.
- Một phiên lặp lại cùng một câu.

## 3. Trải nghiệm

### 3.1 Chọn chế độ
Bấm một dạng bài ở Home / Practice tests mở hộp chọn (mockup "1" trong buổi brainstorm):

| Thành phần | Nội dung |
|---|---|
| Tiêu đề | Kỹ năng + tên dạng bài |
| Lựa chọn 1 | **Tính giờ như thi thật** — mô tả ngắn nhịp thi |
| Lựa chọn 2 | **Không tính giờ** — nghe đề nhiều lần, tự ghi âm, ghi lại thoải mái |
| Số câu | 5 / 10 / Tất cả (mặc định 10; "Tất cả" = toàn bộ câu sẵn sàng của dạng đó, tối đa 50) **[Quyết định của Claude]** |
| Nút | **Bắt đầu** |

- Hộp chọn **thay cho màn Overview** hiện tại: bấm Bắt đầu là tạo phiên và vào câu đầu tiên luôn. **[Quyết định của Claude]**
- Nhớ lựa chọn gần nhất (chế độ + số câu) theo từng dạng bài trong `localStorage` để lần sau chọn sẵn. **[Quyết định của Claude]**
- Nếu dạng bài có ít câu hơn số đã chọn, phiên lấy hết số câu có và hiển thị đúng tổng thật (vd "1/3").
- Mọi kỹ năng đều có hai chế độ; với Writing/Reading/Listening chỉ khác là không có phần ghi âm. **[Quyết định của Claude, Hung đã đồng ý khi duyệt mockup]**

### 3.2 Chế độ tính giờ — nhịp từng câu
Thanh giai đoạn hiển thị trên đầu thẻ câu hỏi, giai đoạn hiện tại được tô màu, có đồng hồ đếm ngược lớn (mockup "2b").

**Speaking** (theo từng dạng, giá trị ở §6):
1. *Đọc/chờ* (`preListenSeconds`, nếu có) → 2. *Nghe đề* (audio tự phát **một lần**, không có nút tua/phát lại) → 3. *Chuẩn bị* (`prepSeconds`) → 4. *Ghi âm* tự bật, sóng âm đỏ chạy theo giọng, đếm ngược `responseSeconds`, có nút **Dừng sớm** → 5. *Xong*: hiện sóng âm tĩnh + nút ▶ nghe lại; **không có nút ghi lại**. **[Đã chốt]**
- Read Aloud / Describe Image không có audio đề: bỏ qua bước nghe đề.
- Nếu micro bị từ chối hoặc lỗi giữa chừng **trước khi có bản ghi được lưu**: dừng đồng hồ, báo lỗi, cho học viên bấm "Thử lại câu này" (bắt đầu lại nhịp câu đó từ đầu, kể cả phát lại đề). **[Quyết định của Claude]**

**Writing / Reading / Listening:**
- Listening có audio: audio tự phát một lần, sau đó đếm ngược `responseSeconds`.
- Còn lại: đếm ngược `responseSeconds` ngay khi vào câu.
- Hết giờ: khoá ô trả lời, hiện "Hết giờ", học viên bấm Nộp bài để nộp phần đã làm (không tự nộp). **[Quyết định của Claude]**

Chuyển sang câu sau thì nhịp bắt đầu lại từ đầu cho câu đó.

**Thoát hoặc tải lại trang giữa chừng rồi quay lại** **[Đã chốt]**:
- Câu **đã có bản ghi được lưu** (draft có `media`): mở lại ở trạng thái **Xong** với bản ghi cũ — không phát lại đề, không ghi lại, vẫn nghe lại được (§3.4). Thoát ra vào lại **không** phải là cách để làm lại.
- Câu **chưa có bản ghi được lưu** (hoặc câu không phải Speaking chưa nộp): chạy lại nhịp từ đầu; không cố khôi phục đồng hồ giữa chừng.
- Bản ghi ở chế độ tính giờ phải được lưu vào draft ngay sau khi upload xong (không đợi bấm Nộp), để trạng thái "đã ghi" sống sót qua thoát/tải lại.

### 3.3 Chế độ không tính giờ
- Không có đồng hồ nào trên màn hình. **[Đã chốt]**
- Audio đề có trình phát đầy đủ, nghe bao nhiêu lần cũng được.
- Speaking: tự bấm **Ghi âm** / **Dừng**; sau khi dừng có sóng âm + ▶ nghe lại + **↺ Ghi âm lại** (mockup "2a"). Ghi lại thay hoàn toàn bản trước. **[Đã chốt]**
- Giới hạn kỹ thuật một bản ghi: tối đa **120 giây**, chạm giới hạn thì tự dừng và báo. **[Quyết định của Claude]** — giữ đúng giới hạn backend đang ép (`PracticeMediaConstants.MAX_RESPONSE_DURATION_SECONDS = 120`, kiểm ở `CloudinaryMediaService` và `PracticeAnswerValidationService`; FE `MAX_RECORDING_DURATION_SECONDS = 120`). Không nâng giới hạn trong spec này.

### 3.4 Trình ghi âm (dùng chung cho cả hai chế độ)
| Trạng thái | Hiển thị |
|---|---|
| Chưa ghi | Nút Ghi âm (không tính giờ) hoặc trạng thái chờ (tính giờ) |
| Đang ghi | Chấm đỏ, **sóng âm sống** vẽ từ mức âm thanh thật của micro, thời lượng đang ghi |
| Đang lưu | "Đang lưu bản ghi…" |
| Đã ghi | **Sóng âm tĩnh** vẽ từ chính bản ghi; ▶/⏸; phần đã phát tô đậm; bấm vào sóng để tua; thời lượng `0:03 / 0:07`; nút ↺ Ghi âm lại (chỉ chế độ không tính giờ) |
| Lỗi lưu | Giữ bản ghi trong trình duyệt, nút "Lưu lại" (thử upload lại), không mất bản ghi |

- Ngay sau khi ghi: nghe lại bằng chính bản ghi trong trình duyệt (object URL).
- **Sau khi tải lại trang / quay lại phiên** **[Đã chốt]**: bản ghi đã lưu trên server phải nghe lại được và có sóng âm — FE lấy link tạm của chính file đó, tải về, giải mã (`decodeAudioData`) để vẽ sóng tĩnh và phát. Backend phải cho học viên lấy link xem của **bản ghi của chính mình** trong phiên của mình (xem §5.1); không mở cho bản ghi của người khác.
- Sóng âm: tính đỉnh biên độ theo cột từ dữ liệu PCM mà `audio-recorder.ts` đã thu (`Float32Array` chunks) — không thêm thư viện. **[Quyết định của Claude]**
- Theo chuẩn FE: không dùng màu cứng ngoài token theme, có nhãn trợ năng, trạng thái không chỉ thể hiện bằng màu.

## 4. Ràng buộc

- **Kiến trúc:** module `practice` của `pte-api` (Spring Modulith, layout `domain/` `dto/` `internal/`), lỗi theo `DomainException` + hằng số trong `PracticeConstants`, sai chủ sở hữu → 404.
- **Migration:** Flyway, bắt đầu **V133**; kiểm số V cao nhất trên `dev` trước khi đặt tên (dễ trùng giữa các nhánh). Migration phải chạy được trên H2 của context test.
- **Idempotency & version:** giữ nguyên cơ chế `Idempotency-Key` + `clientVersion` của mọi lệnh session. Request start mới (có `timingMode`, `questionCount`) phải vào hash idempotency.
- **Phiên đang có:** session cũ (tạo trước V133) không có `timing_mode` → coi là **UNTIMED**, vẫn mở lại và làm tiếp được. V133 xoá `deadline_at` của các phiên chưa kết thúc (`OVERVIEW`, `IN_PROGRESS`) để chúng không bị đánh `EXPIRED` ngay khi mở; phiên đã `EXPIRED` giữ nguyên. **[Quyết định của Claude]**
- **FE `pte-practice`:** chữ hiển thị đi qua i18n `common/i18n` (vi/en); file ≤ 300 dòng, component ≤ 150 dòng (`PracticeSessionView.tsx` hiện ~501 dòng — **phải tách component/hook trước** khi thêm tính năng; phần mới không được làm nó dài thêm); không inline style mới.
- **Trình duyệt:** sóng âm và ghi âm chạy trên Chrome/Edge bản hiện hành; thiếu Web Audio thì vẫn ghi/nghe lại được, chỉ ẩn sóng âm.
- **Không phá API cũ:** `timingMode` và `questionCount` là trường tuỳ chọn; thiếu thì mặc định `UNTIMED` và 10 câu.

## 5. Phần "làm thế nào" đã có hướng

### 5.1 Backend — phiên và câu hỏi
- `PracticeSessionStartRequest` thêm `timingMode` (`TIMED` | `UNTIMED`, mặc định `UNTIMED`) và `questionCount` (1–50, mặc định 10).
- `practice_sessions` thêm cột `timing_mode` (V133). Bỏ hẳn hạn chung: `deadlineAt` và `timeLimitSeconds` của phiên không còn được đặt. Mọi chỗ đang kiểm deadline (`expireIfNeeded`, `requireLiveInProgress`, `heartbeat`, `saveAndExit`, `PracticeMediaBindingService.isPastDeadline`) phải coi `deadline_at = NULL` là "không hết hạn" — vốn đã đúng với code hiện tại nhưng phải có test giữ lại hành vi này.
- Link tạm của audio/ảnh đề (`PRACTICE_PROMPT_MEDIA_TTL_SECONDS`, đang suy ra từ 60 phút) không còn gắn với giới hạn phiên; FE xin lại session khi link hết hạn (phiên không tính giờ có thể kéo dài).
- Nghe lại bản ghi của chính học viên: thêm đường lấy link tạm cho media `STUDENT_RESPONSE_AUDIO` gắn với item thuộc phiên của chính học viên (kiểm chủ sở hữu qua session/item như `PracticeMediaBindingService`), trả 404 cho mọi trường hợp khác.
- Tạo item: với mỗi dạng bài được chọn, lấy tối đa `questionCount` câu **khác nhau**, ngẫu nhiên, **ưu tiên câu học viên chưa từng có trong phiên practice nào của mình**, thiếu thì bổ sung bằng câu đã làm. Giữ nguyên việc "đóng băng" nội dung câu vào item như hiện tại. Thay `findPublishedPracticeQuestionIdsByTaskTypeKey(..., PageRequest.of(0,1))` bằng truy vấn trả về danh sách ứng viên.
  - Không xáo trộn bằng SQL (`RANDOM()`): itembank trả danh sách ID ứng viên, practice tự lấy tập "đã làm" từ bảng của mình, rồi một lớp chọn thuần (có `RandomGenerator` tiêm vào để test xác định) xáo riêng nhóm chưa làm / đã làm. Chạy giống nhau trên Postgres và H2. **[Quyết định của Claude, theo research]**
  - Đóng băng nội dung theo lô (một lần lấy nhiều câu kèm options) thay vì 2 truy vấn mỗi item, vì `begin` đang giữ khoá dòng session — 50 câu × 2 truy vấn là quá chậm.
- `startRequestHash` thêm `timingMode` và `questionCount` **sau khi đã áp mặc định**, để request bỏ trống và request gửi giá trị mặc định cho cùng một hash.
- Response session/item trả thêm `timingMode` và, với phiên TIMED, timing của từng item (`preListenSeconds`, `prepSeconds`, `responseSeconds`).

### 5.2 Backend — thời gian theo dạng bài
- **Nguồn: Score Template đang active** (`ScoreTemplateService.getActive()`, API công khai, không theo tenant), giống cách đề thi lấy thời gian — **không** tạo file timing riêng cho practice. **[Quyết định của Claude, đổi sau research]** — repo đã từng gỡ các bản sao timing để tránh lệch (`config/task-timing.json` ghi rõ "Do NOT add any task type back here"); V14 seed đủ 22 dạng.
- `preListenSeconds` của 5 dạng Speaking có audio đề lấy từ `config/task-timing.json` hiện có (thêm accessor công khai, không chép số). Diễn giải `prep` của các dạng này giống đề thi: là khoảng chờ trước khi ghi (preRecord), áp theo quy tắc "dynamic prep" của `PinnedItem`.
- Không có template active, hoặc template thiếu dạng bài được chọn → lựa chọn **Tính giờ** bị vô hiệu trong hộp chọn với lời giải thích; **Không tính giờ** vẫn dùng được.
- Timing được ghim vào item khi tạo (thêm 3 cột nullable trên `practice_session_items`, cùng V133) để đổi template sau không làm đổi phiên đang làm.
- Phiên tính giờ ghim thời gian cho **mọi** dạng bài, kể cả dạng không ghi âm.

### 5.3 Frontend
- Hộp chọn chế độ mở từ mọi chỗ đang gọi `handleStartIntent` (Home, Practice tests, Skill list). Bỏ màn Overview: tạo phiên rồi gọi `begin` ngay.
- Đồng hồ chung (`session-timer`, `formatRemaining(deadlineAt)`) bị gỡ.
- Thêm một "bộ điều phối nhịp" cho chế độ tính giờ (state machine theo giai đoạn ở §3.2, dạng hook thuần + test) và một component trình ghi âm mới thay `RecordingRenderer` hiện tại, nhận prop `allowRetake` và các mốc thời gian.
- Upload bản ghi giữ nguyên luồng hiện có (`uploadPracticeRecording`); ghi lại = upload bản mới và thay `media` trong draft.

### 5.4 Tái sử dụng component **[Đã chốt: phải dùng common/có sẵn để dễ bảo trì]**

**Thực tế hai repo:** `pte-practice` là repo riêng, **không** phụ thuộc `@pte/ui` của `pte-web` (không có trong `package.json`, không cùng workspace pnpm). Vì vậy "dùng lại" theo thứ tự ưu tiên:

1. **Dùng đúng cái `pte-practice` đã có** — không viết lại:

| Có sẵn | Dùng cho |
|---|---|
| `common/components`: `AppIcon`, `ErrorState`, `LoadingState`, `LockBadge` | icon giai đoạn, lỗi micro/upload, trạng thái tải |
| CSS dùng chung trong `app/globals.css`: `.button` + biến thể (`button-primary`, `-accent`, `-muted`, `-wide`, `-pill`), `.icon-button`, `.text-button`, `.reference-card`, `.state-badge*`, `.session-progress*`, `.form-error`, token màu `--accent`, `--red`, `--green`… | toàn bộ nút, thẻ, nhãn trạng thái, thanh tiến trình — không tạo class "na ná" |
| `features/practice/media/audio-recorder.ts` (`startWavRecording`, `RecorderError`) | thu âm; chỉ **mở rộng** để phát mức âm/PCM cho sóng âm, không viết recorder thứ hai |
| `features/practice/media/api.ts` (`uploadPracticeRecording`) | upload bản ghi và bản ghi lại |
| `renderers/PromptMedia.tsx` | phát audio/ảnh đề; thêm chế độ "phát một lần, không điều khiển" cho tính giờ thay vì component mới |
| `renderers/renderer-registry.tsx` + `TaskRenderer` | điểm cắm renderer; trình ghi âm mới đăng ký thay `RecordingRenderer` tại đây |
| `ConfidenceHint`, i18n `common/i18n` | giữ nguyên |

2. **Cái chưa có thì tạo một lần ở `common/components`** (không để trong feature), và **bám theo API props của component tương ứng trong `@pte/ui`** để sau này chuyển sang `@pte/ui` chỉ là đổi import:

| Component mới (common) | Bám theo `@pte/ui` | Ghi chú |
|---|---|---|
| `Modal` | `Modal` (`open`, `onClose`, `title`, `children`, `footer`, `size`) | hộp chọn chế độ |
| `Stepper` | `Stepper` (`steps: {id,label}[]`, `currentStep`) | thanh giai đoạn Nghe đề → Chuẩn bị → Ghi âm → Xong |
| `AudioWaveform` | — (chưa có ở đâu) | sóng sống + sóng tĩnh có tua; dùng chung cho Speaking và sau này trang Review |
| `CountdownTimer` | — | đồng hồ đếm ngược của giai đoạn |

3. **Không** chép mã từ `pte-web` sang theo kiểu sửa riêng; **không** thêm thư viện UI/waveform mới.

Việc đưa `@pte/ui` thành dependency thật của `pte-practice` (git/published package) là thay đổi hạ tầng, **không** nằm trong spec này.

### 5.5 Thời gian do client giữ
Server **không** từ chối câu trả lời nộp muộn trong practice; nó chỉ lưu chế độ và timing đã ghim. Đây là lựa chọn có chủ ý vì practice không có cược (khác với đề thi của tổ chức). **[Quyết định của Claude]**

## 6. Thời gian cho chế độ tính giờ

Lấy nguyên từ Score Template đang active (`prepSeconds`, `responseSeconds` của từng item) cộng `preListenSeconds` từ `config/task-timing.json` — cùng nguồn với đề thi, nên practice tính giờ luôn khớp với thi thật. Muốn đổi thời gian thì đổi template (qua vendor-web), không sửa code practice. Với Listening, `response` đếm sau khi audio phát xong. **[Quyết định của Claude, đổi sau research — thay bảng số tự đặt ở bản trước]**

## 7. Tiêu chí nghiệm thu

1. Bấm một dạng bài luôn hiện hộp chọn chế độ; bấm Bắt đầu vào thẳng câu 1, không qua Overview.
2. Phiên 10 câu Repeat Sentence (khi kho có ≥ 10 câu) có 10 câu **không trùng**; lần thứ hai ưu tiên câu chưa làm.
3. Chế độ không tính giờ: không có phần tử đếm ngược nào trên màn hình, ở mọi dạng bài.
4. Chế độ tính giờ, Repeat Sentence: audio phát đúng một lần, không có nút phát lại; ghi âm tự bật sau giai đoạn chờ và tự dừng đúng `responseSeconds` (sai lệch ≤ 1 giây); không có nút ghi lại.
5. Không tính giờ: ghi → nghe lại → ghi lại; bản được nộp là bản ghi **cuối cùng** (kiểm bằng `media` trong payload đã lưu).
6. Sóng âm khi ghi thay đổi theo âm lượng thật (im lặng thì gần phẳng); sóng âm tĩnh khớp bản ghi; bấm vào sóng tua đúng vị trí.
7. Upload lỗi không làm mất bản ghi; "Lưu lại" upload thành công thì nộp được.
8. Phiên cũ trước V133 vẫn mở và làm tiếp được (coi là không tính giờ).
9. Test BE: chọn câu không trùng + ưu tiên chưa làm, mặc định chế độ, hash idempotency có chế độ/số câu, timing ghim vào item. Test FE: state machine nhịp tính giờ, tính đỉnh sóng âm, payload ghi lại. Toàn bộ suite BE, `tsc`, eslint, vitest của `pte-practice` xanh.

## 8. Để builder tự quyết
- Số cột của sóng âm, tốc độ làm mới khi ghi, kiểu bo/khoảng cách cột.
- Cách tách `PracticeSessionView.tsx` thành component/hook.
- Thuật toán ngẫu nhiên và cách lấy "câu đã làm" (truy vấn qua `practice_session_items` của học viên) miễn đạt tiêu chí 2.
- Chi tiết chữ hiển thị (vi/en) trong khuôn khổ i18n hiện có.
- Có dùng `Web Audio AnalyserNode` cho sóng sống hay tính từ chunk PCM — miễn đạt tiêu chí 6.
