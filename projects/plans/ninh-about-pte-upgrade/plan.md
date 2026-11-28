# Nâng cấp trang `/about-pte` (tenant-web)

Trạng thái: đã làm xong 3 đợt; code nằm trong pte-web PR #115. Code ở `pte-web/apps/tenant-web/features/aboutPte/`.

## Quyết định

- **Không sửa Dark Mode.** Trang công khai cố ý chỉ có giao diện sáng (`HomeDesign.module.css`: "fixed light art direction", `color-scheme: light`, ghim toàn bộ token), và header công khai không có nút đổi theme. Đổi `bg-white` sang token hay thêm `dark:` đều không bao giờ hiện ra.
- **Không chia tab 4 kỹ năng cho dạng câu hỏi.** Trang đã nhóm 22 dạng theo 3 phần thi (Speaking & Writing thi chung một phần), phần mô tả chi tiết đã thu gọn.
- **Ví dụ "một câu, hai kỹ năng"** lấy từ bảng trọng số thật của trang (Repeat Sentence, Summarize Written Text, Write from Dictation), không dùng Read Aloud: trong bảng này Read Aloud chỉ tính Speaking.
- **Thời gian trả kết quả** ghi "khoảng 2 ngày" cho khớp với bảng so sánh đã có nguồn, không ghi "48 giờ".

## Đợt 1

- 4 thẻ "Vì sao PTE khác biệt" (`_CoreDifferences`), nền navy, đặt trước bảng so sánh.
- Bộ lọc bảng so sánh: Tất cả / PTE và IELTS / PTE và TOEFL (`_ComparisonFilter`, `constants/compareViews.ts`); cột PTE có viền nhấn.
- Thanh mục lục dính + tô sáng mục đang đọc (`_SectionNav`, `useActiveSection`) và nút "Thử giả lập điểm".
- Nguồn tham khảo thu gọn mặc định; bấm số trích dẫn `[n]` sẽ mở danh sách rồi cuộn tới mục đó (`OPEN_SOURCES_EVENT`).
- Banner CTA cuối trang (`_AboutCta`): Đăng ký trung tâm / Đăng nhập.

## Đợt 2

- Bảng quy đổi theo trang chính thức của Pearson, đọc ngày 2026-11-28:
  - IELTS (concordance cập nhật 07/2025): mốc PTE tối thiểu cho từng band: 4.5=24, 5.0=31, 5.5=39, 6.0=47, 6.5=55, 7.0=63, 7.5=71, 8.0=79, 8.5=86, 9.0=90.
  - CEFR: A2 30–42, B1 43–58, B2 59–75, C1 76–84, C2 85–90.
  - Nguồn mới: [15] trang scoring, [16] trang understand-your-score.
- Thanh trượt "Điểm PTE của tôi tương đương bao nhiêu?" (`_ScoreConversion`) với 3 mốc nhanh 50 / 65 / 79 (B1 · IELTS 6.0, B2 · 7.0, C1 · 8.0).
- Hero và bảng điểm của phòng thí nghiệm hiện IELTS và CEFR của điểm Overall.
- Lưu ý: bảng chart trên trang scoring của Pearson còn một biểu đồ CEFR khác (các dải chồng nhau, ghi "roughly"). Trang này dùng bảng từ trang understand-your-score. Mọi chỗ hiển thị đều ghi là tham khảo.

## Đợt 3

- Ba nút "Mục tiêu 50 · B1 / 65 · B2 / 79 · C1" trong phòng thí nghiệm điểm. Mỗi nút đặt mọi dạng câu về cùng một mức rồi chọn mức cho Overall gần mục tiêu nhất (`utils/labScoring.ts`, `valuesForTarget`); lệch tối đa ±2.
- `scoreLab` và `labItemScores` chuyển từ hook sang `utils/labScoring.ts` (hook vẫn export lại).

## Kiểm tra

- Test mới: `scoreConversion`, `labPresets`, `aboutPteExtras` (46 test trong thư mục aboutPte, 1164 test toàn tenant-web đều qua), typecheck và lint sạch.
- Đã xem trên trình duyệt ở 1280px và 375px: không tràn ngang.

## Đợt chỉnh theo nhận xét (vòng 2)

Đối chiếu từng nhận xét với code và trang thật, rồi chỉ làm những ý đúng.

Đã làm:
- Bỏ tên code và ghi chú nội bộ khỏi văn bản công khai (`RubricScorer`, `AggregationCore`, `pte-api`, "(V5)"); viết lại các câu "chưa hiệu chỉnh" và "tần suất chưa kiểm chứng" bằng ngôn ngữ sản phẩm. Có test chặn các chuỗi này quay lại.
- Tiêu đề mọi phần căn giữa (trước đó 3 phần đầu căn giữa, phần sau căn trái).
- Thanh tiến độ ăn màu kỹ năng ở bảng điểm mẫu (cần `!` vì `cn()` không gộp class xung đột).
- Bỏ 2 thẻ `10–90` / `22` ở hero; bỏ banner navy "Mô phỏng chấm điểm" thay bằng tiêu đề gọn; ghi chú bảng điểm mẫu thành "PTE Academic".
- 4 thẻ khác biệt viết theo dạng đối chiếu: dòng PTE và dòng IELTS/TOEFL, độ dài cân nhau.
- Mục "Về PTE" trên menu có trạng thái đang chọn; nút "Thử giả lập điểm" chỉ hiện sau khi cuộn qua hero.
- "Đề tài này" thành "Bài thi này"; "Kỹ năng được báo điểm" thành "Kỹ năng chấm điểm".
- Bảng so sánh: bỏ viền dọc bị cắt ngang bởi các dòng nhóm, thay bằng vạch nhấn ở đầu cột; chuỗi `[1] [4] ...` gom thành "Nguồn đối chiếu (9) ↗".
- Thẻ thành phố dùng icon ghim (thêm `MapPinIcon` vào `@pte/ui`); hộp lưu ý viết lại giọng khách quan.
- Nhãn "Tích hợp" thành badge ở mép phải; nút "Thí sinh làm gì ở từng dạng" có mũi tên xoay.
- Ghi chú cổng Content = 0 vào hộp nền hồng nhạt; mũi tên 2 accordion ra mép phải (prop mới `chevronAtEnd` của `CollapsibleSection`, mặc định tắt).
- Thanh công cụ phòng thí nghiệm: tab dạng segmented, 3 nút mục tiêu viền nhạt (chỉ mục tiêu đang chọn tô đậm), gộp một hàng với Làm tốt nhất / Làm kém nhất / Đặt lại.

Không làm / khác với nhận xét:
- "Container lệch trái, bỏ trống bên phải": không đúng. Mọi phần có cùng độ rộng 1152px và căn giữa (đo ở 1440px). Cái lệch nhịp là tiêu đề, đã sửa ở trên.
- Rà nhãn "Tích hợp" cho Read Aloud và Reading & Writing: Fill in the Blanks: nhãn lấy từ bảng trọng số của template chuẩn trong nền tảng (`scoringWeights.ts`, bản sao của migration V24), nơi hai dạng này chỉ tính một kỹ năng. Score Guide chính thức của Pearson có thể khác; muốn đổi phải đổi template ở backend rồi mới đổi bảng này. Cần xác nhận trước.
- Ví dụ Describe Image còn xuất hiện ở hệ thống chấm điểm (giữ, vì đó là ví dụ minh hoạ chính); các bản lặp ở hero và banner đã bỏ.

## Rà nhãn "Tích hợp" theo Score Guide (đã xong)

Đối chiếu cột "Communicative skills scored" của Pearson PTE Academic Test Taker Score Guide (bản 2026, trang 15–44, đọc ngày 2026-11-28) với bảng trọng số của trang (`scoringWeights.ts`):

- Cả 22 dạng khớp. Đúng 8 dạng tích hợp: Repeat Sentence, Re-tell Lecture, Summarize Group Discussion (Listening + Speaking); Summarize Written Text (Reading + Writing); Summarize Spoken Text và Write from Dictation (Listening + Writing); Highlight Correct Summary và Highlight Incorrect Words (Listening + Reading).
- Read Aloud và Fill in the Blanks (Dropdown) chỉ tính một kỹ năng (Speaking và Reading), nên nhận xét cho rằng hai dạng này là tích hợp không đúng với tài liệu chính thức.
- Nguyên nhân gây hiểu nhầm là tên "Reading & Writing: Fill in the Blanks". Đã đổi ba nhãn Fill in the Blanks sang tên trong Score Guide: "(Dropdown)", "(Drag and Drop)", "(Type In)".
- Test `officialSkills.test.ts` khoá bảng này theo Score Guide.
- Chưa so với migration V24 ở backend; trang này chỉ phản ánh bản sao `scoringWeights.ts`.

## Dải "Điểm khác biệt" bớt trống (vòng 3)

- Lưới 2×2 thay cho 4 cột (ở màn rộng, 4 cột làm chữ rớt 5 dòng và thân thẻ ngắn bị hổng); mỗi thẻ có một con số dẫn đầu (`AI`, `~2 ngày`, `2 kỹ năng`, `10–90`), phần đối chiếu IELTS/TOEFL nằm trong dải nền xám ở chân thẻ với chiều cao tối thiểu bằng nhau.
- Nền navy có ánh sáng nhẹ ở trên và padding dọc gọn hơn (`py-12 lg:py-16`).
- Không làm theo nhận xét:
  - "100% AI": Score Guide 2026 ghi một số dạng (Describe Image, Re-tell Lecture, Respond to a Situation, Summarize Group Discussion, Summarize Written Text, Write Essay, Summarize Spoken Text) còn có chuyên gia duyệt lại Content, nên chỉ ghi `AI`.
  - "~48 giờ": giữ "~2 ngày" cho khớp bảng so sánh có nguồn.
  - Dòng "TOEFL: chấm tách biệt từng kỹ năng" ở thẻ 3: chưa có nguồn nào trong trang xác nhận; thay bằng chiều cao tối thiểu của dải chân thẻ để 4 thẻ thẳng hàng.
  - "Khối chỉ chiếm 60% bề ngang": khung 1152px là chung cho cả trang; chỉ trông hẹp ở màn rất rộng.

## Phần so sánh chứng chỉ (vòng 4)

- 4 thẻ "Nên chọn bài thi nào?": viết thành câu hoàn chỉnh ("Phù hợp nếu bạn…") và có ô chữ cái màu P / I / T / P giống tiêu đề bảng (`constants/testAvatars.ts` dùng chung với bảng).
- Dòng mô tả đầu mục không còn rớt lẻ một chữ: `text-pretty` cho phần intro của mọi section (`_AboutSection`).
- Thẻ quy đổi điểm: `[15] [16]` thành link "Bảng quy đổi của Pearson ↗"; ô PTE Academic nền xanh nhạt, số màu xanh; thêm mốc 10 và 90 ở hai đầu thanh trượt.
- Hàng icon đầu bảng thẳng hàng: icon canh trên (`items-start`) thay vì canh giữa theo khối chữ có số dòng khác nhau (IELTS có tên tổ chức 3 dòng). Đo: cả 4 icon cùng `top = 530`.
- Không làm: "thiếu `mx-auto`": không đúng. Khung của phần này cùng container `max-w-6xl mx-auto` với cả trang; khoảng trống bên phải ảnh chụp đến từ cách chụp (màn rất rộng, có thanh cuộn).

## Thêm TOEFL iBT vào thanh quy đổi (vòng 5)

- Không có bảng PTE–TOEFL trực tiếp của Pearson hay ETS. ETS công bố bảng thang TOEFL iBT 1–6 (từ 21/01/2026) theo CEFR: A1 = 1–1.5, A2 = 2–2.5, B1 = 3–3.5, B2 = 4–4.5, C1 = 5–5.5, C2 = 6 (nguồn [8], đọc trực tiếp trên trang ETS ngày 2026-11-28; công cụ đọc web lỗi `Header overflow` nên dùng trình duyệt của app).
- Ô TOEFL iBT (1–6) = băng ETS xếp cho cùng bậc CEFR với điểm PTE (PTE → CEFR theo Pearson → TOEFL theo ETS). Ghi chú dưới thẻ nói rõ đây là suy ra qua CEFR, không phải bảng trực tiếp.
- ETS còn có biểu đồ TOEFL 1–6 so với IELTS (đang thu trong accordion, chưa đọc); có thể dùng để kiểm chéo sau.

## Khối 22 dạng câu hỏi (vòng 6)

- Nút "Thí sinh làm gì ở từng dạng" căn giữa; mỗi dòng có đường kẻ mờ và nền hover; số thứ tự `01…` màu theo phần thi thay cho dấu tích; badge "Tích hợp" bỏ chấm tròn thừa.
- Chân thẻ nền xám ghi thời lượng từng phần, lấy từ Score Guide 2026 của Pearson (trang 15 trở đi, đọc ngày 2026-11-28): Phần 1 khoảng 76–84 phút, Phần 2 khoảng 23–30 phút, Phần 3 khoảng 31–39 phút; kèm ghi chú "thời gian thực tế thay đổi theo từng đề" (chính Score Guide nói các khoảng này không cộng lại thành tổng thời lượng) và trích dẫn [14].
- Không làm theo nhận xét:
  - Số `54–67`, `29–30`, `30–43` phút: không khớp Score Guide 2026.
  - Gắn "Tích hợp" cho Read Aloud, Reading: Fill in the Blanks (Dropdown), Listening: Fill in the Blanks (Type In): Score Guide 2026 ghi cả ba chỉ tính một kỹ năng (Speaking, Reading, Listening). Bảng của trang khớp Score Guide và có test khoá (`officialSkills.test.ts`).
  - Nới khung `max-w-6xl`: khung đã là `max-w-6xl`, dùng chung cả trang.

## Bung chi tiết 22 dạng (vòng 7)

- Bộ lọc ở đầu phần bung: Tất cả (22) / Speaking & Writing / Reading / Listening và nút "Chỉ dạng tích hợp" (ẩn phần không còn dạng nào); thêm nút "Ẩn mô tả" ở cuối danh sách.
- Nhãn "Tích hợp" thành pill nền nhạt, đồng bộ với 3 thẻ tóm tắt; số `01 / 02 / 03` ăn màu 3 phần thi (`constants/partTones.ts` dùng chung) kèm đường kẻ mảnh kéo tới mép phải.
- `[14]` thành link "Score Guide của Pearson ↗" (mở nguồn rồi tô sáng [14]).
- Không đổi: nhãn `Listening` của Answer Short Question. Score Guide 2026 ghi dạng này chỉ tính Listening dù nằm trong Phần 1; bảng trọng số của phòng thí nghiệm khớp (có test `officialSkills.test.ts`).

## Round 8 - Scoring system
- Accepted: Sankey labels use TASK_NAMES (wider diagram), hover isolates a task/skill and shows weights, platform wording ("Tren nen tang", "thuat toan dem tu tu dong"), source link label, part filter + bottom collapse for rules (CollapsibleSection got optional controlled props), short rules in a denser 3-col grid, chevron on level buttons, accordion 2 title shortened.
- Not a bug: tr. 8 is the worked example, tr. 18 is the Describe Image rule; label now says "Vi du trong Score Guide tr. 8".
- Round 8b (direction 1): non-trait rules (incl. Answer Short Question) as one table per part with the Score Guide page shown once; trait cards stretch to equal height, page ref fixed top-right, odd last card spans 2 columns; red gate sentence removed (gate chip is rose-tinted).
- Round 8c: score levels open in the shared Drawer (one pill per trait, trait chips are shortcuts, score badges tinted by level, "Whole item = 0" on gated zero); inline expansion removed. Section nav shows the language switcher once the site header is out of view (the page is fixed light and the header has no theme toggle).
- Round 8d: language switcher removed again from the section nav (too crowded); public page stays fixed light by design.
- Round 8e: Drawer fixes in @pte/ui: body scroll lock while open; pte-fade-up keyframe now ends on transform:none (translateY(0) kept by the fill made the animated CollapsibleSection the containing block of the fixed Drawer).
- Round 8f: real cause of the 40px uncovered strip under the Drawer was Tailwind space-y-10 on its parent adding margin-bottom to the fixed overlay; Drawer root now has m-0 and the drawer sits outside the space-y container.
- Round 8g (rules header): one summary line (also covers "our own words"), divider under the accordion header, filter tabs left-aligned with counts (22/9/5/8), gate legend chip on the right of the filter row.
- Round 8h: page ref moved into the table header cell (no extra strip); gate-zero level text no longer repeats "whole item = 0"; rose dot on gated trait pills. Grey band behind the accordion title is the hover state of the CollapsibleSection button, left as is. Not done: moving the page ref to the part heading, since Listening mixes p.41 (Summarize Spoken Text) and p.44.
- Round 9 (stepper + flow): Writing ring violet (new CircularProgress "violet" tone, also in the lab scoreboard); step 3 shows (56 + 94) ÷ 2 with Item/Average labels; step 2 points to the rules table above; Sankey hint explains the number beside a line is the weight (unit not claimed as %); stepper card min-height stops the jump between steps; last step button becomes a shortcut to the score lab.
- Round 9b: stepper steps 2-3 no longer empty: visual centred vertically, plus the item formula and gate example (step 2) and the blank-item example (step 3).
- Round 9c: sources list is always open (toggle button and its copy removed); citation links still scroll to and highlight their entries.
- Round 10 (simulator): intro cut to one line under the title + one line under it (the two-mode paragraph removed); chevron on each task row; "best/worst" buttons show a pressed state and clear on manual edit (presets already did); "Trong so N" label always reserves its line so the rings never jump; sticky nav hides "Try the score lab" while the simulation section is active. Rejected: raising the scoreboard sticky offset - it is already top-28, the card only slides under the nav at the very end of the list because the sticky container ends there.
- Round 11 (demo walkthrough): fixed the Read Aloud sentence showing in every trait-based editor. Open findings (not built): mobile has no visible scoreboard while editing (it sits ~1300px below the 22 rows); steps tab changes page height at every step and has no final result summary; Write Essay needs 7 steppers; lab focus text can disagree with the highlighted skill when a row is open but not hovered.
- Round 11b: mobile mini score bar (sticky under the section bar, lg:hidden); steps mode: action row sticky, last step offers "Try it in the score lab", final summary line, no height lock (the jump is below the controls and not visible - a lock would leave ~750px blank on shorter steps); lab: level buttons 0..max for controls up to 6 levels (Read Aloud word count keeps +/-); scoreboard caption now uses the same focus fallback as the lit skills.
- Round 12 (Vietnam): city icons pastel with dark on hover; first bullet (repeated the cards) dropped, remaining bullets get bold leads (Lich thi / Le phi); [11][12][13] become one source link; intro on one line; map labels offset 20; caveat box gets an info icon (new optional Alert icon prop) and a link to https://www.pearsonpte.com/book-now/ (checked: 302 to the same path with a trailing slash).
- Round 12b: map label halo widened from 3px to 5px so the coastline is cut cleanly behind Can Tho and TP. Ho Chi Minh.
- Round 12c: Can Tho label moved under its pin (the left-side label sat on Phu Quoc at svg 50-101 x 399-414 and the 5px halo hid the island).
- Round 13 (history + recognition): Vietnam card became a full-width strip (its "we could not find..." sentence reworded to "no verified market-share figure is available", not removed - it is an honest caveat); topic pills on the four country cards (Canada PTE Core in amber); citations gathered into one "Nguon doi chieu (7)" link under the heading (per-claim marks lost, as in the other sections); timeline line now ends on the last dot, which has a halo and a "most recent" label (not "new": the change dates from 7 Aug 2025); title ends with "?" plus a one-line description.
- Round 14 (sources): list in a white card, whole row is the link with a hover tint and an arrow, dark link text turning blue on hover, fixed-width right-aligned numbers; English suffixes moved to pills (Ben thu ba on 4, 11, 12, 13 - The PIE News is independent trade press - and PDF on 14); the highlight on arrival already existed. Closing CTA already exists after this section (AboutCta), so nothing added.
- Round 14b: source pills share a fixed cluster with the arrow at the right edge, so long titles wrap on the left only.
- Round 15 (closing CTA): rejected the width claim (card and sources card both measure 929px) - widened only the headline to max-w-3xl with text-balance so no orphan word; copy keeps the real onboarding step ("duoc duyet") but speaks to the centre; navy glow and "for training centres" pill; arrow on the primary button; stronger outline on the secondary. The pasted review was cut off mid-sentence at the last point.
- Round 16 (overview): "PTE la gi?"; [1][14] became one source link; nbsp keeps "2 ngay" / "2 gio" together; left column in a soft card so both columns end level (492px each; no new claims added - "fully automatic scoring" was not used, Pearson uses human content review on some tasks); one-line description under the title; the four stat cards are links (types/length -> #basics, scale/skills -> #scoring) with a hover lift and equal heights.
- Round 17: the "Why PTE differs" band is now light (navy tone removed from AboutSection as dead code); overview became the tint band and the card on the left of it a white card, so bands alternate tint/plain down to the sources; SourceRefs got a "standalone" prop (no left margin) used under the overview text and the Vietnam bullets - link and heading now share one left edge (65px).
- Round 18 (hero): scrollspy kept the last section lit after scrolling back up (state was never cleared when the reading band was empty) - fixed, nothing lit above the first section; hero headline balanced (text-balance) with a 6fr/5fr split; secondary button now "Thu gia lap diem" (same as the nav); primary button arrow points down (it scrolls on the same page). Not done: centring the nav list (it would shift when the CTA appears), tilt (already straightens on hover, kept), aligning the hero with the logo (header container is 1240px, page sections 6xl).
- Round 19 (mobile pass, 375px): the page scrolled sideways by 60px because the segmented Tabs (comparison filter) did not shrink - the common Tabs now scroll inside their own box (max-w-full, overflow-x-auto); headline numbers of the stat cards no longer split ("10-/90"); the section nav scrolls its lit entry into view; short rules render as stacked entries on phones (the rule column was off-screen in the table). Left as is: the skill-flow chart and the comparison table scroll sideways inside their frames.
- Round 20 (closing CTA again): navy card replaced by a light tint card laid out in a row (text left, buttons right; stacked on phones) so the footer is the only dark block at the end; headline now follows on from what was just read; secondary button is "Thu gia lap diem" (scrolls up to the lab) instead of "Dang nhap", which the header already has. Open question: whether visitors are mainly candidates or centres.
- Round 21 (for readers new to PTE; the page is the web-app landing page, not a project write-up): new sections - sample questions (Read Aloud, Describe Image, Write From Dictation, drawn up by us, not Pearson items), test day (4 steps taken only from Pearson PTE Academic page, source 1: authorised centre on a computer not at home, rooms up to 15 seats, ~2 h single test, Score Report typically within 2 days, free unlimited score sending, valid two years; headset and timing details left out because not verified), and an 8-term glossary. Catalogs in aboutPteGuide.{en,vi}.ts with a parity test. Not added to the section nav (already 8 entries).
- Round 22 (check of the sample screens against Pearson): Write From Dictation had a manual "Play audio" button, wrong - on the real test the audio starts by itself and plays once (Pearson Listening format page), so it is now a status bar plus a response box; Read Aloud and Describe Image got the status box with a progress bar; each card now states its timing (30-40 s / 25 s + 40 s / 3-5 s audio). Sources 17 and 18 (Pearson test-format pages, Speaking & Writing and Listening) added. pte-practice was compared by code only (task-instructions.ts mirrors Pearson wording; practice mode allows re-recording, the real test does not); its dev server was not running.
- Round 23 (footer, shared by the home page): two tiers - brand (mark turned white with brightness-0 invert) + main links + back to top, then the Pearson trademark notice and the copyright; now a client component using the home/about copy for labels. Not changed: the footer frame is the same 1240px container as the header, so brand and logo line up; the page sections use a narrower one (see round 18).
