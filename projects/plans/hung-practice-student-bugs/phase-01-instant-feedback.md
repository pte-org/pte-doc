# Phase 1: Chấm và hiện đúng/sai ngay cho câu có đáp án sẵn

Preflight: Unit tests created and run: no (skipped_by_user) · ck:quality gate: skipped_by_user
Status: Completed · Bug: "Làm câu có đáp án sẵn xong không thấy đúng/sai, bấm Tiếp theo là sang câu khác luôn"

## Requirements

- Câu có đáp án sẵn (chọn một, chọn nhiều, điền từ vào chỗ trống có menu hoặc kéo thả) được chấm lúc trả lời. Học viên thấy ngay từng lựa chọn đúng hay sai, rồi mới bấm Tiếp theo.
- Bỏ chữ "AI scoring" ở những dạng bài chấm theo đáp án; thiết kế lại ô kết quả cho đầy hơn: vòng điểm lớn có chuyển động, số đếm từ 0 lên điểm, bỏ nhãn Low/Medium/High.
- Điểm trung bình cuối phiên ghi rõ đang tính trên bao nhiêu câu đã chấm.
- Phiên MOCK_TEST chưa nộp thì không trả cờ đúng/sai.

## Design Constraints

- `optionVerdicts` chỉ trả khi câu đã chấm (`SCORED`) và khoá có ít nhất một đáp án đúng; không thì trả danh sách rỗng.
- Một file ở `internal/**` không quá 300 dòng. `PracticeScoringStateService.java` đang đúng 300 dòng.
- Chuỗi hiển thị cho học viên nằm ở `common/i18n` (vi/en/types) hoặc `constants.ts` của feature, không viết cứng trong component.

## Related files

`pte-api`: `practice/internal/dto/response/PracticeItemResultResponse.java` (thêm `optionVerdicts`, `withoutOptionVerdicts()`), `…/service/response/PracticeOptionVerdictReader.java` (mới), `…/service/PracticeScoringStateService.java`, `…/service/PracticeResponseService.java`, `…/service/PracticeReviewService.java`, `…/service/session/PracticeSessionService.java`.

`pte-practice`: `features/practice/result-contracts.ts`, `features/practice/renderers/{choice-verdict.ts,choice-verdict.css,ChoiceOptionList.tsx,ChoiceRenderer.tsx,BlankRenderer.tsx,blank-verdict.ts}`, `features/practice/session/{instant-feedback.ts,footer-buttons.ts,useHistoryHydration.ts,session-history.ts,complete-actions.ts,SessionStateCards.tsx}`, `features/practice/review/{ObjectiveResultCard.tsx,objective-result.ts,review-choice.ts,review-blank.ts,ReviewAnswerPane.tsx,ReviewQuestion.tsx}`, `features/practice/ScoreDial.tsx`, `common/components/{ScoreGauge.tsx,score-gauge-geometry.ts}`, `common/hooks/useCountUp.ts`, `common/i18n/*`.

## Steps

1. Backend: `PracticeOptionVerdictReader` đọc lựa chọn của học viên (`selectedOption`/`selectedOptions` theo `orderIndex` cho dạng chọn; `selections`/`placements` theo văn bản ở từng `blankIndex` cho dạng điền chỗ trống) và đối chiếu với khoá.
2. `PracticeScoringStateService.resultOf` gắn verdict khi câu đã chấm; `PracticeResponseService.resultOf(session, response)` bỏ verdict của MOCK_TEST chưa kết thúc; review và session service gọi bản có `session`.
3. Frontend: renderer chọn/điền tô đúng-sai theo `optionVerdicts`; nút chân trang đổi thành Tiếp theo sau khi đã có kết quả; phục hồi từ lịch sử khi tải lại trang.
4. Ô kết quả: `ScoreGauge` dùng chung, `useCountUp`, thẻ kết quả to bằng thẻ đề; dòng "tính trên N câu đã chấm" ở tổng kết phiên.

## Success Criteria

- Trả lời một câu chọn nhiều đáp án: ngay sau đó từng lựa chọn hiện đúng/sai và có điểm; bấm Tiếp theo mới sang câu sau.
- Câu điền từ có menu thả: mỗi chỗ trống hiện đúng/sai.
- Phiên MOCK_TEST đang làm: phản hồi không chứa `optionVerdicts`.
- Tổng kết phiên nói rõ điểm trung bình dựa trên bao nhiêu câu.

## Quality and Testing State

- Quality: skipped_by_user
- Testing: skipped_by_user. `b67f9ed` có kèm các file test được commit trước khi Hung bảo bỏ; chưa quyết định giữ hay bỏ.
