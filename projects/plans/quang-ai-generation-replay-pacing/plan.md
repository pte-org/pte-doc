# Sinh đề AI: nhịp phát lại và chuyển câu trong lô

**Trạng thái:** Hoàn tất (2026-11-26) · **Tác giả:** quang · **Ngày:** 2026-11-26
**Nguồn:** [brainstorm.md](brainstorm.md)
**Phạm vi:** chỉ `pte-web/apps/vendor-web`, không đổi backend hay API.
**Chuẩn bắt buộc:** `pte-web/docs/CODING_STANDARDS_WEB.md`, `pte-web/AGENTS.md`

## Mục tiêu

- Chữ gõ với tốc độ giống nhau trên mọi màn hình, có lựa chọn tốc độ và nút Hiện hết.
- Field vào preview đủ chậm để nhìn theo kịp.
- Trang lô giữ nguyên câu đang xem; chỉ chuyển câu khi user bấm Next.

## Các phase

| # | Phase | Trạng thái | File |
|---|---|---|---|
| 1 | Gõ theo thời gian, chọn tốc độ, Hiện hết | [x] | [phase-01-time-based-typing.md](phase-01-time-based-typing.md) |
| 2 | Nhịp kéo field vào preview | [x] | [phase-02-drop-pacing.md](phase-02-drop-pacing.md) |
| 3 | Trang lô: giữ câu và nút Next | [x] | [phase-03-batch-focus-next.md](phase-03-batch-focus-next.md) |

Thứ tự: 1 → 2 → 3. Phase 3 dùng `onReplayDone`, mà callback này cần cả trạng thái gõ (phase 1) lẫn `idle` của hàng đợi field (phase 2).

## Kiểm tra chung (mỗi phase)

Chạy từ `pte-web/apps/vendor-web`:

```bash
pnpm exec tsc --noEmit
pnpm exec eslint features/questiongeneration features/batchgeneration tests/unit/features
pnpm exec vitest run tests/unit/features/questiongeneration tests/unit/features/batchgeneration
```

- Không mở trình duyệt; user tự kiểm tra giao diện.
- Mỗi file ≤ 300 dòng, mỗi component ≤ 150 dòng.
- Chữ hiển thị đặt trong constants (vi/en).
- Dùng component của `@pte/ui` như được cung cấp, không chỉnh lại kiểu dáng.

## Ngoài phạm vi

- Nhãn model dự phòng và gợi ý chuyển model trong thẻ chờ, xem [brainstorm của kế hoạch fallback](../quang-ai-generation-streaming-fallback/brainstorm.md).
- Lưu trạng thái "đã xem" lên server.
