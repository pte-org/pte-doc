# Phase 3: Rà soát & Chuẩn hóa Hằng số (Constants Standardization)

**Status:** Completed  
**Owner:** Hung  
**Commit:** `42eca04`  
**Files:**
- [`common/providers/constants.ts`](file:///d:/GitHub/PTE-org/pte-practice/common/providers/constants.ts)
- [`common/providers/theme-init.ts`](file:///d:/GitHub/PTE-org/pte-practice/common/providers/theme-init.ts)
- [`common/providers/ThemeProvider.tsx`](file:///d:/GitHub/PTE-org/pte-practice/common/providers/ThemeProvider.tsx)
- [`features/practice/constants.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/constants.ts)
- [`features/practice/session-storage.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/session-storage.ts)
- [`features/practice/useAccessToast.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/useAccessToast.ts)
- [`features/practice/mode/mode-preference.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/mode/mode-preference.ts)
- [`features/practice/api.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/api.ts)
- [`features/practice/presentation.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/presentation.ts)
- [`features/practice/PracticeProvider.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/PracticeProvider.tsx)
- [`features/deviceCheck/device-check.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/deviceCheck/device-check.ts)
- [`features/deviceCheck/useDeviceChecks.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/deviceCheck/useDeviceChecks.ts)
- [`features/deviceCheck/DeviceCheckDialog.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/deviceCheck/DeviceCheckDialog.tsx)
- [`features/practice/renderers/SpeakingRecorder.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/renderers/SpeakingRecorder.tsx)
- [`features/home/constants.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/home/constants.ts)
- [`features/home/RecommendationCarousel.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/home/RecommendationCarousel.tsx)
- [`common/i18n/types.ts`](file:///d:/GitHub/PTE-org/pte-practice/common/i18n/types.ts)
- [`common/i18n/en.ts`](file:///d:/GitHub/PTE-org/pte-practice/common/i18n/en.ts)
- [`common/i18n/vi.ts`](file:///d:/GitHub/PTE-org/pte-practice/common/i18n/vi.ts)

---

## 1. Bảng Tổng hợp Chuẩn hóa Hằng số (Constants Audit)

### 1.1 Storage Keys & Event Names
| Khóa cũ (Hardcode rải rác) | Vị trí mới trong Constants | File sử dụng |
| :--- | :--- | :--- |
| `"pte.practice.session"` | `PRACTICE_STORAGE_KEYS.session` | [`session-storage.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/session-storage.ts) |
| `"pte.practice.draft."` | `PRACTICE_STORAGE_KEYS.draftPrefix` | [`session-storage.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/session-storage.ts) |
| `"pte.practice.unlocked_toast_shown"` | `PRACTICE_STORAGE_KEYS.unlockedToast` | [`useAccessToast.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/useAccessToast.ts) |
| `"pte.practice.mode."` | `PRACTICE_STORAGE_KEYS.modePrefix` | [`mode-preference.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/mode/mode-preference.ts) |
| `"pte.practice.device-check."` | `PRACTICE_STORAGE_KEYS.deviceCheckPrefix` | [`device-check.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/deviceCheck/device-check.ts) |
| `"pte.practice.reading-size"` | `PRACTICE_STORAGE_KEYS.readingSize` | [`device-check.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/deviceCheck/device-check.ts) |
| `"pte.practice.device-check-changed"` | `PRACTICE_STORAGE_KEYS.deviceCheckEvent` | [`useDeviceChecks.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/deviceCheck/useDeviceChecks.ts) |

### 1.2 Theme, Animation & Ripple Configuration
Được định nghĩa trong [`common/providers/constants.ts`](file:///d:/GitHub/PTE-org/pte-practice/common/providers/constants.ts):
```ts
export const THEMES = {
  DARK: "dark",
  LIGHT: "light",
} as const;

export type Theme = (typeof THEMES)[keyof typeof THEMES];

export const THEME_ATTRIBUTE = "data-theme";
export const THEME_STORAGE_KEY = "pte-practice-theme";
export const DEFAULT_THEME: Theme = THEMES.DARK;
export const THEME_PROVIDER_REQUIRED = "useTheme must be used within a ThemeProvider";

export const THEME_TRANSITION_CONFIG = {
  durationMs: 450,
  easing: "cubic-bezier(0.2, 0.9, 0.3, 1)",
  switchDelayMs: 350,
  fadeDelayMs: 100,
  removeDelayMs: 300,
  rippleColors: {
    dark: "#1e1e1e",
    light: "#F7F7F7",
  },
} as const;
```

### 1.3 Carousel Parameters
Tạo mới file [`features/home/constants.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/home/constants.ts):
```ts
export const CAROUSEL_ANIMATION_DURATION_MS = 450;
export const CAROUSEL_SNAP_RESTORE_DELAY_MS = 400;
export const CAROUSEL_DEFAULT_CARD_WIDTH = 300;
export const CAROUSEL_GAP = 16;
export const CAROUSEL_DRAG_THRESHOLD_PX = 4;
```

### 1.4 Magic Numbers & Magic Strings trong Practice
Được định nghĩa trong [`features/practice/constants.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/constants.ts):
- `DEFAULT_PRACTICE_QUESTION_COUNT = 10` (áp dụng vào `DEFAULT_MODE_PREFERENCE` trong `mode-preference.ts`).
- `DEFAULT_API_BASE_URL = "http://localhost:8080"` (áp dụng vào `getApiBaseUrl()` trong `api.ts`).
- `ENTITLEMENT_STALE_THRESHOLD_MS = 10_000` (áp dụng vào `refreshIfStale` trong `PracticeProvider.tsx`).
- `SCORE_TONE_THRESHOLDS = { LOW: 40, HIGH: 70 } as const` (áp dụng vào `scoreTone()` trong `presentation.ts`).
- `SKILL_SHORT_NAMES` (thay thế khối `switch-case` hardcode song ngữ trong `skillShortName()` trong `presentation.ts`).
- `CHECK_VALID_DAYS = 7`, `CHECK_VALID_MS = CHECK_VALID_DAYS * 24 * 60 * 60 * 1000` (trong `device-check.ts`).

### 1.5 Khử trùng lặp chuỗi cấp quyền Microphone sang i18n
Định nghĩa trong `deviceCheck`:
```ts
micStep1: "Bấm vào icon Cài đặt / Ổ khóa 🔒 ở bên trái thanh địa chỉ trình duyệt Chrome (cạnh URL).", // vi
micStep1: "Click the site settings / lock icon 🔒 on the left of the Chrome address bar.", // en
micStep2: "Chuyển Microphone sang Cho phép (Allow), sau đó quay lại trang này.", // vi
micStep2: "Switch Microphone to Allow, then return to this page.", // en
```
Sử dụng bằng `t("deviceCheck.micStep1")` và `t("deviceCheck.micStep2")` trong cả:
- [`features/deviceCheck/DeviceCheckDialog.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/deviceCheck/DeviceCheckDialog.tsx)
- [`features/practice/renderers/SpeakingRecorder.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/renderers/SpeakingRecorder.tsx)

---

## 2. Kết quả kiểm tra
- TypeScript: `pnpm typecheck` thành công (`0 errors`).
- Unit test: `pnpm test:unit` thành công toàn diện: `49/49 test files passed` (240 tests passed).
