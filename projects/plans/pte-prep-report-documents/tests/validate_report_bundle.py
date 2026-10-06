"""Structural/content checks for the project-specific PTE Prep Reports 3-6 bundle.

This is documentation validation, not a product runtime test. It deliberately
fails before the report bundle exists so ck:cook can use it as the RED test for
the documentation work package.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


REPO_ROOT = next(
    (parent for parent in Path(__file__).resolve().parents if parent.name == "pte-org"),
    Path(__file__).resolve().parents[5],
)
REPORT_ROOT = REPO_ROOT / "pte-doc" / "report"

EXPECTED_FILES = {
    "report03": [
        "00-project-report.md",
        "00-record-of-changes.md",
        "01-overall-description.md",
        "02-user-requirements.md",
        "03-functional-requirements.md",
        "04-non-functional-requirements.md",
        "05-requirement-appendix.md",
    ],
    "report04": [
        "00-project-report.md",
        "00-record-of-changes.md",
        "01-system-design.md",
        "02-database-design.md",
        "03-detailed-design.md",
    ],
    "report05": [
        "00-project-report.md",
        "00-record-of-changes.md",
        "01-scope-of-testing.md",
        "02-test-strategy.md",
        "03-test-plan.md",
        "04-test-cases.md",
        "05-test-reports.md",
    ],
    "report06": [
        "00-project-report.md",
        "00-record-of-changes.md",
        "01-deliverable-package.md",
        "02-installation-guides.md",
        "03-user-manual.md",
    ],
}

FOUNDATION_FILES = [
    "section-map.md",
    "actor-feature-catalog.md",
    "status-evidence-matrix.md",
    "id-ledger.md",
    "tbd-register.md",
    "evidence-catalog.md",
    "pte-task-catalog.md",
]

ACTORS = [
    "Platform Admin",
    "Platform Author",
    "Host",
    "Proctor",
    "Examiner",
    "Student",
    "External Integration Services",
]

GENERIC_TOKENS = [
    "[Project name]",
    "[Describe",
    "<<",
    "insert a class diagram",
    "Cafeteria",
    "Patron",
]


def fail(message: str, failures: list[str]) -> None:
    failures.append(message)


def read_markdown(path: Path, failures: list[str]) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        fail(f"invalid UTF-8: {path}: {exc}", failures)
    except OSError as exc:
        fail(f"cannot read {path}: {exc}", failures)
    return ""


def validate() -> int:
    failures: list[str] = []
    markdown: dict[Path, str] = {}

    if not REPORT_ROOT.is_dir():
        fail(f"missing canonical report root: {REPORT_ROOT}", failures)

    for report_name, filenames in EXPECTED_FILES.items():
        report_dir = REPORT_ROOT / report_name
        if not report_dir.is_dir():
            fail(f"missing report directory: {report_dir}", failures)
            continue
        assets = report_dir / "assets"
        if not assets.is_dir():
            fail(f"missing mandatory assets directory: {assets}", failures)
        for filename in filenames:
            path = report_dir / filename
            if not path.is_file():
                fail(f"missing expected report file: {path}", failures)
                continue
            markdown[path] = read_markdown(path, failures)

    foundation_dir = REPORT_ROOT / "_foundation"
    validation_dir = REPORT_ROOT / "_validation"
    if not foundation_dir.is_dir():
        fail(f"missing foundation directory: {foundation_dir}", failures)
    if not validation_dir.is_dir():
        fail(f"missing validation directory: {validation_dir}", failures)
    for filename in FOUNDATION_FILES:
        path = foundation_dir / filename
        if not path.is_file():
            fail(f"missing foundation file: {path}", failures)
        else:
            markdown[path] = read_markdown(path, failures)

    validation_report = validation_dir / "report-03-06-validation.md"
    if validation_report.is_file():
        markdown[validation_report] = read_markdown(validation_report, failures)

    all_text = "\n".join(markdown.values())
    for path, text in markdown.items():
        if "\ufffd" in text and path.name != "section-map.md":
            fail(f"replacement character in final Markdown: {path}", failures)
        for token in GENERIC_TOKENS:
            if token in text:
                fail(f"generic/sample token {token!r} remains in {path}", failures)

    for actor in ACTORS:
        if actor not in all_text:
            fail(f"approved actor missing from report bundle: {actor}", failures)
    for forbidden in ["Lecturer", "Program Coordinator", "Tenant Owner"]:
        occurrences = [line for line in all_text.splitlines() if forbidden in line]
        # The foundation deliberately names prohibited roles to prevent scope
        # drift. Reject a forbidden role only when it is defined as a product
        # actor or used as an active workflow role, not when it appears in an
        # explicit exclusion/prohibition statement.
        active_occurrences = [
            line for line in occurrences
            if not re.search(r"(?i)(prohibit|must not|not a .*role|outside|exclude|excluded|additional .*role|not introduce)", line)
        ]
        if active_occurrences:
            fail(f"unapproved product role appears as active role: {forbidden}", failures)

    if "PTE Prep" not in all_text:
        fail("PTE Prep product name is missing", failures)
    if "PTE Academic" not in all_text:
        fail("PTE Academic independence boundary is missing", failures)
    if "Planned/Future" not in all_text or "TBD" not in all_text:
        fail("status vocabulary is incomplete", failures)

    task_catalog = markdown.get(foundation_dir / "pte-task-catalog.md", "")
    task_rows = re.findall(r"^\|\s*PT-\d{2}\s*\|", task_catalog, flags=re.MULTILINE)
    if len(task_rows) != 23:
        fail(f"expected exactly 23 task catalog rows, found {len(task_rows)}", failures)
    if "Personal Introduction" not in task_catalog:
        fail("unscored Personal Introduction is missing from task catalog", failures)

    for path, text in markdown.items():
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
            if target.startswith(("http://", "https://", "#")):
                continue
            target_path = (path.parent / target.split("#", 1)[0]).resolve()
            if target_path and not target_path.is_file() and not target_path.is_dir():
                fail(f"broken relative link in {path}: {target}", failures)

    if failures:
        print("RED/FAILED")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("GREEN/PASSED")
    print(f"Validated {len(markdown)} Markdown files under {REPORT_ROOT}")
    return 0


if __name__ == "__main__":
    sys.exit(validate())
