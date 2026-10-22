# Rubric và ma trận task cho Practice

Date: 2026-10-22. Status: Proposed, cần Academic Manager duyệt nội dung/anchors.
Đây là rubric giáo dục nội bộ PTEPrep, không phải công bố thang điểm chính thức Pearson.

## 1. Rubric là gì trong ứng dụng

Rubric là bộ tiêu chí nói rõ bài cần làm được điều gì, thế nào là đạt/chưa đạt và phải dựa trên bằng chứng nào. Prompt là chỉ dẫn dùng rubric cho AI; prompt không thay rubric. Rubric cũng không chỉ là trọng số hoặc tên model. Một câu hỏi phải có reference/answer key đúng trước khi AI có thể giải thích đáng tin cậy.

Luồng đề xuất: Academic Staff soạn -> submit -> Academic Manager review/reject/publish -> phiên mới pin published revision. Publication không mặc định cho phép Staff tự duyệt; emergency Platform Admin action nếu có phải explicit policy và audit. Host/Proctor/Examiner không được đổi rubric nền của phiên practice chỉ vì có vai trò trong kỳ thi.

## 2. Nội dung một rubric revision

| Thành phần | Ví dụ/cách dùng |
|---|---|
| Identity | `PRACTICE.WRITE_ESSAY`, revision `1`; immutable sau publish |
| Compatibility | task code, renderer/answer schema, evaluator policy tương thích |
| Criterion ID/title | `TASK_FULFILMENT`, `COHERENCE`, `GRAMMAR`, `VOCABULARY` |
| Descriptor levels | Chưa đủ bằng chứng / Cần cải thiện / Đạt cơ bản / Tốt, mô tả cụ thể cho từng criterion |
| Applicability | Criterion nào bắt buộc, có thể NA, evidence tối thiểu và rule kết luận LIMITED |
| Form constraints | Word/sentence/time limits lấy từ pinned task policy; deterministic validation, không model tự chọn |
| Reference materials | Human reference answer, accepted variants, source transcript/image annotations với revision/provenance |
| Anchors | Bài mẫu và đánh giá chuẩn, ví dụ lỗi/off-topic/empty, giải thích vì sao đạt level đó |
| Scoring policy | Feedback-only mặc định đề xuất; numeric range/weights/zero rules nếu đã calibration và approved |
| Review | Author, reviewer, decision/reason/time, release/retirement, change notes |

Rubric v2 không thay rubric v1 của phiên đã tạo. Retired rubric không dùng cho phiên mới nhưng vẫn đọc được lịch sử khi có quyền. Không xóa hard rubric đang được session/evaluation tham chiếu.

## 3. Ví dụ descriptor Writing, chưa là thang điểm chính thức

Ví dụ task Write Essay hỏi ưu/nhược của học trực tuyến. Số chữ và form lấy từ task policy, không hardcode số trong rubric demo.

| Criterion | Cần cải thiện | Đạt cơ bản | Tốt | Evidence |
|---|---|---|---|---|
| TASK_FULFILMENT | Lạc đề hoặc thiếu một phần yêu cầu chính | Nêu đúng chủ đề và hai phía nhưng giải thích còn sơ lược | Giải quyết đủ yêu cầu, luận điểm và ví dụ liên quan | Span nêu luận điểm/ví dụ đối chiếu prompt |
| COHERENCE | Các câu rời, mối quan hệ ý không rõ | Có mở/thân/kết và chuyển ý hiểu được | Trình tự hợp lý, mỗi đoạn phát triển một ý, liên kết phù hợp | Paragraph IDs và connective spans |
| GRAMMAR | Lỗi lặp làm khó hiểu quan hệ câu | Có lỗi nhưng ý chính hiểu được | Cấu trúc câu phù hợp và lỗi nhỏ không cản hiểu | Exact quote + vị trí + sửa đề xuất |
| VOCABULARY | Từ dùng sai nghĩa hoặc lặp làm mờ ý | Từ đủ diễn đạt, một số chỗ chưa tự nhiên | Từ/collocation chính xác, phù hợp chủ đề | Quote và context, không invent lỗi ngoài bài |
| FORM | Deterministic pass/fail/invalid theo giới hạn đã pin | Không nhờ AI ước lượng word count | Không cộng điểm vì model thích độ dài | Server counts/policy version |

Empty/garbled/off-topic không bắt model khen đủ tiêu chí. `NOT_ASSESSABLE` khác “0 điểm”: chỉ numeric 0 khi score policy đã định nghĩa và đủ điều kiện áp dụng.

Summarize Written/Spoken Text thêm coverage của key ideas, faithful meaning, no unsupported additions, và format riêng; không chấm essay structure cho summary một câu. Academic anchors và accepted paraphrases phải cho phép cách diễn đạt khác đáp án mẫu.

## 4. Khách quan và Speaking

Khách quan: đúng/sai/partial credit/penalty theo evaluator đã pin. Gemini giải thích vì sao option của Student đúng/sai, dấu hiệu trong passage/transcript, cách tránh lỗi. Không đổi đáp án do model tự suy thấy option khác hợp hơn. Nếu reference lỗi thì trả issue cần academic review, không tự chữa nguồn và overwrite lịch sử.

Speaking: nội dung/coverage/task response qua transcript + source/reference. Phát âm cần âm thanh và assessor phù hợp; fluency cần audio timing, pauses và policy được kiểm định. Transcript-only không đủ hai loại nhận xét đó. Với audio nhiễu/không có tiếng/thiếu source thì LIMITED hoặc NOT_ASSESSABLE; Student vẫn nghe lại bài đã lưu nếu có quyền.

| Speaking task | Nhận xét nội dung | Evidence bắt buộc |
|---|---|---|
| READ_ALOUD | Word coverage/substitution/omission | Prompt text + bound audio; alignment/assessor khi chấm phát âm |
| REPEAT_SENTENCE | Từ/ý được lặp lại so với source | Source transcript giữ server + source audio + response audio |
| DESCRIBE_IMAGE | Main trend/relationships/key values, tránh bịa số | Image pinned + academic annotations + transcript/audio |
| RE_TELL_LECTURE | Key points và faithful summary | Lecture audio/transcript + response |
| ANSWER_SHORT_QUESTION | Accepted answer/semantic variants | Prompt source + accepted variants + audio/transcript; không coi cần Gemini cho mọi đáp án |
| RESPOND_TO_A_SITUATION | Fulfilment, appropriateness/register | Situation requirements + response |
| SUMMARIZE_GROUP_DISCUSSION | Speaker contributions/relationships/main topic | Source speakers/transcript/audio + response |
| PERSONAL_INTRODUCTION | Coaching tự giới thiệu nếu được bật | Audio/transcript, luôn unscored |

## 5. Inventory canonical theo D01 đã xác nhận

Source of truth: `pte-api/app/src/main/java/com/pte/itembank/domain/enums/PteTaskType.java` và `TaskRuntimeProfileRegistry.java`. Vocabulary có 23 entries. User xác nhận D01 ngày 2026-10-22: dùng các dạng bài Academic đã có trong ngân hàng, không mở thêm Core riêng. Inventory cần đối chiếu nội dung, rubric và runtime readiness; task chưa đủ dữ liệu là gap cần làm, không tự bỏ khỏi phạm vi hoặc tuyên bố runnable.

`Baseline runnable` bên dưới chỉ là allowlist source ngày 2026-10-22, không chứng minh bài/media thực tế chạy đúng. Mọi row in-scope phải qua delivery→submit→review và rubric/evidence readiness; chỉ thêm renderer key không đủ.

| # | Canonical task | Baseline runnable | Delivery/answer cần có | Evaluation/explanation đề xuất |
|---|---|---|---|---|
| 01 | PERSONAL_INTRODUCTION | Có | Text instructions, preparation/recording, bound audio | Unscored, optional coaching |
| 02 | READ_ALOUD | Có | Prompt text, timing, audio record/replay | Audio evidence + word coverage; pronunciation gated assessor |
| 03 | REPEAT_SENTENCE | Chưa | Prompt audio, playback policy, record | Source/response alignment; thiếu audio không fabricated score |
| 04 | DESCRIBE_IMAGE | Chưa | Prompt image + alt policy không leak annotations, record | Image-grounded reference + transcript |
| 05 | RE_TELL_LECTURE | Chưa | Source audio/optional allowed image, record | Key ideas từ source, không hallucinated content |
| 06 | ANSWER_SHORT_QUESTION | Chưa | Source prompt/audio, short recording | Accepted variants; explanation if useful |
| 07 | RESPOND_TO_A_SITUATION | Chưa | Situation prompt/source, record | Task fulfilment/register |
| 08 | SUMMARIZE_GROUP_DISCUSSION | Chưa | Discussion audio, speaker source, record | Speaker points/relationships |
| 09 | SUMMARIZE_WRITTEN_TEXT | Có | Passage, editor, limits | Summary rubric, deterministic form |
| 10 | WRITE_ESSAY | Có | Prompt, editor, limits | Essay rubric/evidence; numeric gated |
| 11 | MC_READING_SINGLE | Có | Passage + stable option ID | Deterministic correctness + reference rationale |
| 12 | MC_READING_MULTIPLE | Có | Passage + set option IDs | Deterministic partial/penalty policy |
| 13 | RE_ORDER_PARAGRAPHS | Có | Shuffled blocks + stable IDs, keyboard reorder | Pinned pair/order policy; IDs/orderIndex phải không lộ đáp án |
| 14 | FILL_IN_THE_BLANKS_DRAG_AND_DROP | Có | Dynamic blanks, word bank, reuse policy | Per-blank evaluator, không hardcode 2 blank |
| 15 | FILL_IN_THE_BLANKS_DROPDOWN | Có | Dynamic blank groups/options | Per-blank option groups, grammar/context explanation |
| 16 | SUMMARIZE_SPOKEN_TEXT | Chưa | Source audio, editor, limits | Summary rubric + source transcript server |
| 17 | MC_LISTENING_SINGLE | Chưa | Audio + stable option ID | Deterministic + post-submit evidence |
| 18 | MC_LISTENING_MULTIPLE | Chưa | Audio + option set | Deterministic partial/penalty |
| 19 | FILL_IN_THE_BLANKS_TYPE_IN | Chưa | Audio + passage/blank IDs, typed slots | Accepted forms/normalization pinned |
| 20 | HIGHLIGHT_CORRECT_SUMMARY | Chưa | Audio + summary options | Correct option + source-grounded explanation |
| 21 | SELECT_MISSING_WORD | Chưa | Audio + candidate endings | Correct option + context |
| 22 | HIGHLIGHT_INCORRECT_WORDS | Chưa | Audio + displayed transcript tokens | Stable token IDs, deterministic selections/penalty |
| 23 | WRITE_FROM_DICTATION | Chưa | Audio + editor | Versioned alignment/accepted words/normalization |

Reorder/highlight sorting: không đưa correct-order indexes ra Student như IDs có thể suy đáp án. Public shuffled tokens/options có opaque IDs riêng, evaluator mapping phía server. Cần compatibility adapter đối với clients hiện có dùng orderIndex, không đổi wire format lặng lẽ.

`WRITE_EMAIL` chưa có canonical runtime; video chưa có contract chứng minh. Hai capability này ngoài đợt triển khai đã chốt; bổ sung sau cần work package riêng, không map WRITE_EMAIL sang essay.

## 6. Mẫu lời giải cho Student

Ví dụ khách quan đã nộp option B nhưng key được duyệt là C:

1. **Bài của bạn:** B — lưu nguyên lựa chọn.
2. **Kết quả hệ thống:** Chưa đúng. Đáp án C theo version câu hỏi này.
3. **Vì sao:** Dẫn phrase/đoạn cụ thể ủng hộ C; chỉ rõ B đánh tráo quan hệ nào. Nếu evidence không đủ, model không được invent quote.
4. **Cách làm tốt hơn:** Tìm câu chứa quan hệ nguyên nhân/kết quả trước khi so options.
5. **Nguồn đánh giá:** Rubric/evaluator revision và nhãn AI; Student không cần thấy key/prompt secrets.

Ví dụ Writing: “Ý chính phù hợp nhưng đoạn 2 thiếu ví dụ. Ở câu ‘…’, thì động từ chưa thống nhất; có thể sửa thành ‘…’. Lần luyện sau viết một ví dụ cụ thể cho mỗi luận điểm.” Không dùng nhận xét giống hệt cho mọi Student và không khẳng định band/score chính thức.

## 7. Bộ kiểm định học thuật

Tạo ít nhất 8 bài chuẩn/task có chấm, bao gồm good/medium/weak, off-topic, empty/invalid, adversarial instructions, lỗi source hoặc missing evidence. Academic Manager quyết định labels/acceptable paraphrases; người duyệt khác người viết khi policy yêu cầu. Không tự lấy output Gemini làm gold label.

Kiểm ba lớp: schema/evidence valid; đúng nội dung/đáp án; lời khuyên có ích và bám rubric. Với subset, gọi độc lập 3 lần để xem criteria/conclusions drift, không tái dùng cache trong phép đo. Khả năng read result ổn định được kiểm riêng bằng repeated GET.

Nếu cần điểm ước lượng Writing/Speaking: chọn numeric range/weights, corpus có human reference, sai số/thoả thuận người chấm, ngưỡng và nguồn benchmark trước khi triển khai gate. Không invent tolerance hoặc normalize rubric level thành score 10–90 chỉ vì UI muốn số. Feedback-only và numeric-capable được công bố thành capabilities độc lập.

Rubric chưa có academic approval là DRAFT; không cho task AI-ready dựa riêng tồn tại prompt. Task có thể delivery-ready nhưng feedback limited/unavailable theo policy catalog; mọi lời hứa “complete” cần nói rõ task và capability đã nghiệm thu.
