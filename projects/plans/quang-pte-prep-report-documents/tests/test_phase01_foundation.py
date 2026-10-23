"""RED/GREEN checks for Phase 01 documentation foundation."""

from __future__ import annotations

import re
import sys
from pathlib import Path


REPO_ROOT = next(parent for parent in Path(__file__).resolve().parents if parent.name == "pte-org")
REPORT_ROOT = REPO_ROOT / "pte-doc" / "report"
FOUNDATION = REPORT_ROOT / "_foundation"

FOUNDATION_FILES = [
    "section-map.md",
    "actor-feature-catalog.md",
    "status-evidence-matrix.md",
    "id-ledger.md",
    "tbd-register.md",
    "evidence-catalog.md",
    "pte-task-catalog.md",
]

REPORT_COVERS = {
    "report03": "Software Requirement Specification",
    "report04": "Software Design Document",
    "report05": "Testing Documentation",
    "report06": "Release Package & User Guides",
}

EXPECTED_ACTORS = [
    "Platform Admin",
    "Platform Author",
    "Host",
    "Proctor",
    "Examiner",
    "Student",
    "External Integration Services",
]


def main() -> int:
    failures: list[str] = []
    if not REPORT_ROOT.is_dir():
        failures.append(f"missing report root: {REPORT_ROOT}")
    if not FOUNDATION.is_dir():
        failures.append(f"missing foundation directory: {FOUNDATION}")
    if not (REPORT_ROOT / "_validation").is_dir():
        failures.append("missing validation directory")

    texts: list[str] = []
    for filename in FOUNDATION_FILES:
        path = FOUNDATION / filename
        if not path.is_file():
            failures.append(f"missing foundation file: {path}")
            continue
        text = path.read_text(encoding="utf-8")
        texts.append(text)
        if "\ufffd" in text:
            failures.append(f"replacement character in foundation file: {path}")

    for report, title in REPORT_COVERS.items():
        report_dir = REPORT_ROOT / report
        for filename in ["00-project-report.md", "00-record-of-changes.md"]:
            path = report_dir / filename
            if not path.is_file():
                failures.append(f"missing Phase 01 report baseline: {path}")
            else:
                text = path.read_text(encoding="utf-8")
                texts.append(text)
                if "PTE Prep" not in text:
                    failures.append(f"PTE Prep missing from {path}")
        cover = report_dir / "00-project-report.md"
        if cover.is_file() and title not in cover.read_text(encoding="utf-8"):
            failures.append(f"DOCX document-level title missing from {cover}")

    all_text = "\n".join(texts)
    for actor in EXPECTED_ACTORS:
        if actor not in all_text:
            failures.append(f"actor missing: {actor}")
    if "EVD-" not in all_text:
        failures.append("EVD evidence namespace missing")
    if "Current" not in all_text or "Partial" not in all_text or "Planned/Future" not in all_text:
        failures.append("status vocabulary incomplete")

    task_catalog = (FOUNDATION / "pte-task-catalog.md")
    if task_catalog.is_file():
        task_text = task_catalog.read_text(encoding="utf-8")
        rows = re.findall(r"^\|\s*PT-\d{2}\s*\|", task_text, flags=re.MULTILINE)
        if len(rows) != 23:
            failures.append(f"expected 23 task rows, found {len(rows)}")
        if "Personal Introduction" not in task_text:
            failures.append("Personal Introduction missing")

    if failures:
        print("RED/FAILED")
        print("\n".join(f"- {failure}" for failure in failures))
        return 1
    print("GREEN/PASSED: Phase 01 foundation is structurally valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())

