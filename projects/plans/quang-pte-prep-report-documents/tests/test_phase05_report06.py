"""RED/GREEN structural checks for the project-specific Report 6 guides."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = next(parent for parent in Path(__file__).resolve().parents if parent.name == "pte-org")
REPORT = ROOT / "pte-doc" / "report" / "report06"
FILES = [
    "00-project-report.md",
    "00-record-of-changes.md",
    "01-deliverable-package.md",
    "02-installation-guides.md",
    "03-user-manual.md",
]
ROLES = ["Platform Admin", "Platform Author", "Host", "Proctor", "Examiner", "Student"]


def main() -> int:
    failures: list[str] = []
    texts: dict[str, str] = {}
    for name in FILES:
        path = REPORT / name
        if not path.is_file():
            failures.append(f"missing Report 6 file: {path}")
            continue
        texts[name] = path.read_text(encoding="utf-8")
    combined = "\n".join(texts.values())
    for phrase in [
        "PTE Prep",
        "PTE Academic",
        "organization web portal",
        "platform administration portal",
        "Windows-first exam client",
        "prerequisite",
        "health",
        "rollback",
        "troubleshooting",
        "retry",
        "TBD",
        "masked",
    ]:
        if phrase.lower() not in combined.lower():
            failures.append(f"required Report 6 phrase missing: {phrase}")
    for role in ROLES:
        if role not in combined:
            failures.append(f"Report 6 workflow role missing: {role}")
    for identifier in ["FR-ONBOARD-002", "FR-EXAM-004", "FR-DELIVERY-006", "FR-INTEGRITY-003", "FR-SCORE-005", "FR-REPORT-003", "NFR-18", "SD-ARCH-DEPLOY-001", "SEQ-ANSWER-SYNC", "TC-DELIVERY-003"]:
        if identifier not in combined:
            failures.append(f"Report 6 traceability link missing: {identifier}")
    for prefix in ["WF-", "STEP-", "IMG-"]:
        if prefix not in combined:
            failures.append(f"Report 6 guide namespace missing: {prefix}")
    if "password=" in combined.lower() or "private key" in combined.lower() and "do not" not in combined.lower():
        failures.append("Report 6 appears to contain an unsafe credential instruction")
    if "official PTE" in combined and "not" not in combined.lower():
        failures.append("Report 6 may imply official PTE service without an independence boundary")
    for phrase in ["error", "expected result", "audit", "visibility", "support"]:
        if phrase.lower() not in combined.lower():
            failures.append(f"Report 6 workflow detail missing: {phrase}")
    if failures:
        print("RED/FAILED")
        print("\n".join(f"- {failure}" for failure in failures))
        return 1
    print("GREEN/PASSED: Report 6 guides are structurally valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())

