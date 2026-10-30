"""RED/GREEN structural checks for the project-specific Report 5 testing set."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = next(parent for parent in Path(__file__).resolve().parents if parent.name == "pte-org")
REPORT = ROOT / "pte-doc" / "report" / "report05"
FILES = [
    "00-project-report.md",
    "00-record-of-changes.md",
    "01-scope-of-testing.md",
    "02-test-strategy.md",
    "03-test-plan.md",
    "04-test-cases.md",
    "05-test-reports.md",
]


def main() -> int:
    failures: list[str] = []
    texts: dict[str, str] = {}
    for name in FILES:
        path = REPORT / name
        if not path.is_file():
            failures.append(f"missing Report 5 file: {path}")
            continue
        texts[name] = path.read_text(encoding="utf-8")
    combined = "\n".join(texts.values())
    for phrase in [
        "PTE Prep",
        "Scope of Testing",
        "Test Strategy",
        "Test Plan",
        "Test Cases",
        "Test Reports",
        "planned",
        "execution evidence",
        "tenant isolation",
        "retry",
        "TBD",
    ]:
        if phrase.lower() not in combined.lower():
            failures.append(f"required Report 5 phrase missing: {phrase}")
    for identifier in ["FR-EXAM-003", "FR-DELIVERY-006", "FR-INTEGRITY-003", "FR-SCORE-006", "FR-REPORT-003", "NFR-09", "SD-EXAM-STATE-001", "DB-INV-006", "SEQ-ANSWER-SYNC"]:
        if identifier not in combined:
            failures.append(f"Report 5 traceability link missing: {identifier}")
    for prefix in ["OBJ-", "TC-", "BUG-"]:
        if prefix not in combined:
            failures.append(f"Report 5 testing namespace missing: {prefix}")
    case_rows = re.findall(r"^\|\s*TC-[A-Z0-9-]+\s*\|", combined, flags=re.MULTILINE)
    if len(set(case_rows)) < 12:
        failures.append(f"Report 5 contains too few distinct test-case rows: {len(set(case_rows))}")
    if re.search(r"(?im)^\s*(?:status|result|outcome)\s*[:|].*\bpassed\b", combined):
        failures.append("Report 5 appears to claim an executed Passed result without a result record")
    for phrase in ["negative", "authorization", "duplicate", "conflict", "offline", "provider", "publication"]:
        if phrase.lower() not in combined.lower():
            failures.append(f"Report 5 coverage phrase missing: {phrase}")
    if not (REPORT / "assets" / "README.md").is_file():
        failures.append("Report 5 asset README/evidence convention missing")
    if failures:
        print("RED/FAILED")
        print("\n".join(f"- {failure}" for failure in failures))
        return 1
    print("GREEN/PASSED: Report 5 testing documentation is structurally valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())

