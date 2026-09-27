# ADR-007: Định danh sinh viên & cơ chế đăng nhập

**Date:** 2026-09-16
**Status:** Accepted
**Context:** [ADR-006](ADR-006-commercialization-and-exam-templates.md) chuyển nền tảng sang mô hình **bán sỉ cho nhiều trung tâm**. Mô hình định danh hiện tại — `User.email` unique toàn hệ thống, đăng nhập bằng email — chặn cứng tình huống cơ bản nhất của mô hình đó: một người học ở hai trung tâm.

---

## Vấn đề

`User.email` là `unique = true` toàn cục ([User.java:36](../../../pte-api/app/src/main/java/com/pte/identity/domain/User.java#L36)) và `UserService.create()` kiểm `existsByEmail()` **không scope theo tenant** ([UserService.java:79](../../../pte-api/app/src/main/java/com/pte/identity/internal/service/UserService.java#L79)).

> Nguyễn Văn A học ở trung tâm X, được X import roster với `a@gmail.com`. Ba tháng sau A chuyển sang trung tâm Y. Y import `a@gmail.com` → **409 EmailAlreadyUsedException**.
>
> Theo cô lập tenant, Y không nhìn thấy gì của X — với Y đây là email chưa từng tồn tại. Y không có cách nào tự xử lý, X không biết mình đang chặn Y, không ai gỡ được trừ Admin nền tảng.

Hai hệ quả:

1. **Chặn nghiệp vụ.** Học viên đổi trung tâm, hoặc học song song ở trường đại học và trung tâm luyện thi, là chuyện thường gặp trong mô hình bán sỉ.
2. **Rò rỉ xuyên tenant.** Thông báo lỗi cho phép dò email nào đã tồn tại trong hệ thống bằng cách thử import.

---

## Decision

**Tách khoá đăng nhập ra khỏi email, và tách khoá nghiệp vụ ra khỏi cả hai.** Sinh viên được cấp tài khoản do hệ thống sinh; email trở về đúng vai trò thông tin liên lạc.

### Ba khoá, ba mục đích — đừng lẫn

| Khoá | Phạm vi unique | Ai cấp | Dùng để |
|---|---|---|---|
| `username` | **Toàn cục** | Hệ thống sinh: `{tenant.code}.{random}` (student) / chính là email (vai trò khác) | Đăng nhập — khoá duy nhất `AuthService` tra |
| `studentCode` | **Không unique**, nullable | Không dùng trong luồng import | Trường hồ sơ tuỳ chọn, giữ lại cho nghiệp vụ sau |
| `email` | **Không unique**, nullable | Tuỳ | Thông báo, khôi phục mật khẩu. Không còn là định danh |

Với sinh viên, **không trường nào lấy từ file của trung tâm được dùng làm khoá** — định danh do hệ thống sinh ngẫu nhiên.

**Mọi vai trò khác vẫn kiểm trùng bằng email.** `HOST_ADMIN`, `HOST_AUTHOR`, `PROCTOR`, `LECTURER`, `PROGRAM_COORDINATOR`, `PLATFORM_ADMIN`, `PLATFORM_AUTHOR` được tạo từng người một với email thật, nên `email` = `username` và unique toàn cục vẫn đúng và vẫn giữ. Hai luồng tạo người dùng khác nhau về bản chất: các vai trò đó là cá nhân có email riêng, sinh viên là dòng trong roster.

### Vì sao `username` unique toàn cục mà vẫn đạt "unique theo tenant"

Yêu cầu nghiệp vụ là *"trung tâm Y không bị chặn bởi dữ liệu của trung tâm X"*, không phải *"cột này phải có unique constraint hai cột"*. Hai cách đạt được:

| | Unique thật theo `(tenant_id, username)` | Unique toàn cục, **sinh có tiền tố tenant** |
|---|---|---|
| Hai tenant cùng có `sv0042` | Được | Không xảy ra — thành `fpt.sv0042` và `ames.sv0042` |
| Đăng nhập | **Phải nhập thêm mã tổ chức** — `findByUsername` trả nhiều dòng | `findByUsername()` trả đúng một dòng, không đổi gì |
| Chi phí | Thêm một ô nhập cho mọi sinh viên, thêm một chỗ sai | 0 |

**Chọn cách thứ hai.** Tiền tố tenant cho cùng kết quả nghiệp vụ mà không phải đụng vào cơ chế đăng nhập. Sinh viên của hai trung tâm không bao giờ va nhau vì tiền tố khác nhau — va chạm bị loại trừ *khi sinh*, không phải bị *phát hiện* lúc ghi.

### `Tenant.code` — tổ chức tự đặt, hệ thống kiểm trùng

Tiền tố lấy từ `Tenant.code`, **do tổ chức tự chọn khi nộp đơn đăng ký**, hệ thống kiểm unique. Chưa có trong `tenancy`.

Cho tổ chức tự đặt vì đó là thứ sinh viên của họ nhìn thấy mỗi ngày — `fpt.a7k2m9` dễ nhận hơn `t042.a7k2m9`. Nhưng kéo theo ba thứ phải xử:

1. **Giữ chỗ từ lúc nộp đơn, không phải lúc duyệt.** Hai đơn đang chờ cùng xin `fpt`, duyệt cả hai → va nhau. Mã bị chiếm ngay khi `TenantApplication` được tạo; đơn bị từ chối hoặc hết hạn thì trả mã về.
2. **Admin vẫn có quyền bác.** Tổ chức tự đặt không có nghĩa là muốn gì cũng được — mã mạo danh thương hiệu khác, hoặc mã chung chung kiểu `pte`, `ielts`, là lý do chính đáng để từ chối đơn. Đây là một phần của việc thẩm định (ADR-006 §1), không phải một luật riêng.
3. **Bất biến sau khi duyệt.** Đổi `code` là làm hỏng mọi `username` đã phát. Không có API đổi.

### Một đường đăng nhập cho mọi vai trò

`username` là khoá duy nhất `AuthService` tra cứu. Mọi vai trò khác (`PLATFORM_*`, `HOST_*`, `PROCTOR`, `LECTURER`, `PROGRAM_COORDINATOR`) có `username` **chính là email của họ** — về mặt trải nghiệm họ vẫn "đăng nhập bằng email", không có gì thay đổi. Sinh viên dùng tài khoản được cấp.

Lợi ích của việc gộp về một cột là ở **tầng code, không phải tầng DB**: `AuthService` có đúng một đường tra cứu cho mọi vai trò, thay vì rẽ nhánh theo role rồi tra hai cột khác nhau. Một đường tra thì một chỗ sai; hai đường tra thì hai chỗ sai và một chỗ nữa ở đoạn quyết định rẽ nhánh nào.

Partial index (`WHERE email IS NOT NULL AND role <> 'STUDENT'`) **là khả thi** — project đang chạy Flyway nên viết được SQL thủ công. Không chọn nó vì nó giải bài toán ở DB mà để nguyên sự phức tạp ở tầng đăng nhập, tức trả chi phí mà không mua được thứ đáng mua.

`AuthService.login()` đổi `findByEmail` → `findByUsername`. Đó là toàn bộ thay đổi ở tầng auth.

---

## Hệ quả phải làm

### `identity`

- `User` thêm `username` (`nullable = false, unique = true`); `email` bỏ `unique`, cho nullable
- **`fullName` chuyển thành nullable** — không còn cột nào bắt buộc trong luồng import sinh viên
- `studentCode` giữ nguyên là trường hồ sơ tuỳ chọn, **không** thêm ràng buộc nào
- `BulkCreateUsersRequest` đổi hình dạng: không còn là danh sách `BulkCreateUserRow` có schema, mà là **file + số lượng tài khoản cần sinh**
- `DuplicateEmailInBatchException` → không còn dùng cho luồng student
- `EmailAlreadyUsedException` chỉ còn áp dụng cho các vai trò không phải `STUDENT`
- **Kết quả bulk import là một file `.xlsx`** (file gốc + cột `account` + cột `password`), không phải JSON response — trung tâm cần cầm file đó để phát tài khoản

### Sinh `username`

`{tenant.code}.{random}`. Phần random sinh từ nguồn ngẫu nhiên mật mã, đủ dài để không đoán được tài khoản của sinh viên khác trong cùng trung tâm. Ổn định theo vòng đời — **không đổi khi sinh viên chuyển lớp, chuyển chương trình, hay đổi email**.

Sinh ngẫu nhiên nên về lý thuyết có thể trùng; bắt `DataIntegrityViolationException` trên unique constraint rồi sinh lại, giới hạn số lần thử. Không dùng vòng lặp kiểm-trước-khi-ghi — nó vừa thừa vừa không chống được race.

### Tài khoản sinh viên không có tính liên tục giữa các trung tâm

Chốt rõ: **rời trung tâm A sang trung tâm B thì tài khoản A không dùng được nữa, B cấp tài khoản hoàn toàn mới.** Không có ghép nối, không có chuyển hồ sơ, không có "một người – nhiều trung tâm".

Đây không phải hạn chế kỹ thuật mà là hệ quả trực tiếp của bất biến #1 trong ADR-006 (*bán sỉ, sinh viên không phải khách hàng*): tài khoản sinh viên là **tài sản trong roster của trung tâm**, không phải danh tính cá nhân trên nền tảng. Lịch sử thi ở A ở lại với A — đúng theo cô lập tenant.

Hệ quả chấp nhận có chủ đích: một người học ở hai nơi giữ hai tài khoản, hai mật khẩu, và không có chỗ nào xem được tiến bộ của mình xuyên trung tâm. Với sản phẩm bán sỉ thì đó không phải tính năng bị thiếu — nó nằm ngoài mô hình.

### Import roster: unique theo tài khoản sinh ra, không theo dữ liệu nghiệp vụ

**Chốt: khoá unique duy nhất cho sinh viên là `username` do hệ thống sinh, phạm vi tenant.** Không kiểm trùng theo email, mã học viên, hay họ tên.

Hệ quả phải ghi rõ, vì nó có giá: trung tâm import nhầm cùng một file Excel hai lần sẽ tạo ra 500 sinh viên trùng và hệ thống không nói gì. ADR-006 §4 khiến `Tenant.studentLimit` trở thành ràng buộc được enforce, nên **sinh viên trùng ăn vào hạn mức đã mua**. Đây là đánh đổi có chủ đích: không có khoá nghiệp vụ nào đủ tin cậy trên dữ liệu mà các trung tâm thực sự cung cấp, nên thà không đối chiếu còn hơn đối chiếu sai.

Luồng import gồm ba lớp:

**Lớp 1 — passthrough: hệ thống không diễn giải cột nào.** Không có cột bắt buộc, không có file mẫu bắt buộc, không ánh xạ cột. Trung tâm upload file của họ; nền tảng đếm số dòng, sinh đúng bấy nhiêu tài khoản, và **xuất lại chính file đó kèm hai cột mới: `account` và `password`**.

Lý do bỏ cả `fullName`: trung tâm hay tách thành hai cột `Họ` và `Tên`, hoặc đặt tên cột theo kiểu riêng. Bất kỳ cột nào bị coi là bắt buộc cũng sẽ sai với một định dạng nào đó. Hệ thống không cần biết cột nào là gì — file roster là **tài liệu của trung tâm**, nền tảng chỉ gắn thông tin đăng nhập vào đó.

Hệ quả: `User.fullName` phải chuyển thành nullable, và hồ sơ sinh viên trong DB gần như trống — việc đối chiếu tài khoản với người thật nằm ở file mà trung tâm giữ, không nằm ở hệ thống.

> **Lưu ý bảo mật của thiết kế này:** file xuất ra chứa mật khẩu dạng chữ thường (chưa băm) cho toàn bộ roster. Cần cho tải một lần, không lưu lại file trên server, và **buộc đổi mật khẩu ở lần đăng nhập đầu**. Một file rò ra là lộ toàn bộ tài khoản của trung tâm đó.

**Lớp 2 — không đối chiếu trùng theo dữ liệu nghiệp vụ.** Ràng buộc unique duy nhất là trên `username`, phạm vi tenant. Mỗi dòng trong file là một sinh viên mới và được cấp một tài khoản mới; hệ thống không so dòng đang import với sinh viên đã có.

Đoạn mã trong `username` là **ngẫu nhiên**, không sinh từ dữ liệu đầu vào. Nó nhất quán với lớp 1: hệ thống không đọc nội dung file thì cũng không thể lấy gì trong đó ra làm khoá.

**Ranh giới trách nhiệm (chốt 2026-09-16): dữ liệu roster trùng lặp thuộc trách nhiệm của trung tâm, không phải của nền tảng.** Hệ thống không phát hiện, không cảnh báo, không dọn hộ. Ghi ra đây để nó là một quyết định có chủ, không phải một lỗ hổng bị bỏ quên — và để khi trung tâm khiếu nại về hạn mức bị tiêu vì import nhầm thì đã có câu trả lời từ trước.

**Lớp 3 — bắt buộc có bước xem trước.** Trước khi ghi, hiện số sinh viên sẽ tạo và **hạn mức sau import** (`987 / 1000 chỗ`). Theo ADR-006 §4, import là thao tác **tiêu tiền** — trung tâm phải thấy mình sắp dùng bao nhiêu chỗ *trước* khi bấm, không phải sau.

Đây cũng là lớp phòng vệ duy nhất còn lại trước việc import nhầm hai lần: không có cơ chế tự phát hiện, nên con số ở bước xem trước là thứ duy nhất cho trung tâm cơ hội nhận ra mình sắp tạo 500 sinh viên thay vì 0.

### Migration

**Hệ thống chưa có dữ liệu thật (xác nhận 2026-09-16)** → không có gì để migrate. Schema viết thẳng dạng cuối cùng trong các migration hiện có (`V2__identity.sql`, `V3__tenancy.sql`), DB dựng lại từ đầu.

Nếu sau này cần áp mô hình này lên một hệ đã có dữ liệu thì cách đúng là **backfill `username = email` cho toàn bộ user, kể cả sinh viên** — không sinh username mới cho sinh viên cũ, vì làm vậy là đá họ ra khỏi hệ thống và bắt trung tâm phát lại tài khoản cho cả roster. Hai thế hệ tài khoản cùng tồn tại được, vì `username` là một cột phẳng, không phải định dạng được parse ở đâu cả.

---

## Consequences

**Được:** một người học ở nhiều trung tâm không còn bị chặn. Hết rò rỉ dò email xuyên tenant. Trung tâm import được file Excel bất kỳ, không cần có sẵn cột mã sinh viên. Sinh viên không cần có email để thi — đúng thực tế học sinh phổ thông.

**Trả giá:**
- Thêm một khái niệm (`username`) vào model vốn chỉ có email. Ba khoá cho một người là chỗ dễ lẫn — bảng ở trên tồn tại để chống chuyện đó.
- **Không còn cơ chế phát hiện import trùng**, và trách nhiệm được chuyển sang trung tâm một cách tường minh. Bước xem trước là lớp phòng vệ duy nhất, và nó phụ thuộc vào việc người dùng có đọc con số hay không. Hệ quả tiền bạc là thật: sinh viên trùng ăn vào hạn mức đã mua.
- Cần `Tenant.code`, tức thêm một trường tổ chức tự đặt lúc nộp đơn, phải giữ chỗ từ lúc nộp chứ không phải lúc duyệt, và **không được đổi về sau** (đổi là làm hỏng username đã phát).
- Quên mật khẩu qua email không dùng được cho sinh viên không có email → trung tâm phải reset hộ. `ResetPasswordRequest` hiện đã là luồng host-reset nên không phát sinh gì mới, nhưng đừng thiết kế luồng self-service email-based cho sinh viên.

**Chưa giải:** vấn đề tương tự vẫn còn với các vai trò không phải `STUDENT`. Một `LECTURER` dạy ở hai trung tâm cũng không có hai tài khoản được, vì `username` của họ là email và email là thật. Chưa gặp trong thực tế nên chưa xử lý — nhưng nếu gặp thì lời giải không giống sinh viên, vì các vai trò đó cần email thật để nhận thông báo.

---

## Cần chốt

Không còn câu hỏi nào chặn việc triển khai.

### Đã giải (2026-09-16)

| Câu hỏi | Kết luận |
|---|---|
| Tiêu chí "nghi trùng" khi import roster | **Không đối chiếu** — unique chỉ trên `username` sinh ngẫu nhiên, phạm vi tenant. Roster trùng là trách nhiệm của trung tâm |
| File Excel mỗi trung tâm một định dạng | v1 nhận rộng rãi, chỉ bắt buộc `fullName`; chuẩn hoá và ánh xạ cột để sau |

| Câu hỏi | Kết luận |
|---|---|
| `Tenant.code` ai đặt | Tổ chức tự chọn khi nộp đơn, hệ thống kiểm unique, Admin có quyền bác, bất biến sau khi duyệt |
| `studentCode` bắt buộc hay tự sinh | Không phải khoá — hệ thống sinh phần định danh ngẫu nhiên, `studentCode` tụt xuống thành trường hồ sơ tuỳ chọn |
| Sinh viên chuyển trung tâm | Không có tính liên tục — tài khoản mới hoàn toàn ở trung tâm mới |
