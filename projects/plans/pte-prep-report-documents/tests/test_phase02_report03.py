"""RED/GREEN structural checks for the project-specific Report 3 SRS."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = next(parent for parent in Path(__file__).resolve().parents if parent.name == "pte-org")
REPORT = ROOT / "pte-doc" / "report" / "report03"
FILES = [
    "00-project-report.md",
    "00-record-of-changes.md",
    "01-overall-description.md",
    "02-user-requirements.md",
    "03-functional-requirements.md",
    "04-non-functional-requirements.md",
    "05-requirement-appendix.md",
]
ACTORS = ["Platform Admin", "Platform Author", "Host", "Proctor", "Examiner", "Student", "External Integration Services"]
FEATURES = [f"FEAT-{number:02d}" for number in range(1, 13)]


def main() -> int:
    failures: list[str] = []
    texts: dict[str, str] = {}
    for name in FILES:
        path = REPORT / name
        if not path.is_file():
            failures.append(f"missing Report 3 file: {path}")
            continue
        texts[name] = path.read_text(encoding="utf-8")

    combined = "\n".join(texts.values())
    required_phrases = [
        "independent",
        "PTE Academic",
        "organization-first",
        "Windows-first",
        "registration",
        "package activation",
        "fixed exam version",
        "local-first",
        "retry",
        "Out of scope",
        "TBD",
        "target",
    ]
    for phrase in required_phrases:
        if phrase.lower() not in combined.lower():
            failures.append(f"required Report 3 phrase missing: {phrase}")
    for actor in ACTORS:
        if actor not in combined:
            failures.append(f"actor missing from Report 3: {actor}")
    for feature in FEATURES:
        if feature not in combined:
            failures.append(f"feature missing from Report 3: {feature}")

    fr_ids = re.findall(r"^####\s+(FR-[A-Z0-9-]+)\b", combined, flags=re.MULTILINE)
    nfr_ids = re.findall(r"^####\s+(NFR-[A-Z0-9-]+)\b", combined, flags=re.MULTILINE)
    uc_ids = re.findall(r"^####\s+(UC-[A-Z0-9-]+)\b", combined, flags=re.MULTILINE)
    br_ids = sorted(set(re.findall(r"\bBR-[A-Z0-9-]+\b", combined)))
    for label, values in [("FR", fr_ids), ("NFR", nfr_ids), ("UC", uc_ids), ("BR", br_ids)]:
        if len(values) < 3:
            failures.append(f"Report 3 has too few {label} identifiers: {len(values)}")
    if len(set(fr_ids)) != len(fr_ids):
        failures.append("duplicate FR identifiers in Report 3")
    if len(set(nfr_ids)) != len(nfr_ids):
        failures.append("duplicate NFR identifiers in Report 3")
    task_catalog = (ROOT / "pte-doc" / "report" / "_foundation" / "pte-task-catalog.md").read_text(encoding="utf-8")
    if len(re.findall(r"\|\s*PT-\d{2}\s*\|", task_catalog)) != 23:
        failures.append("Report 3 does not link to the complete PT task catalog")
    if "Student self-payment" not in combined and "personal packages" not in combined:
        failures.append("Student self-payment boundary missing")
    if "contract" not in combined.lower() or "retention" not in combined.lower():
        failures.append("contract-based retention boundary missing")
    if failures:
        print("RED/FAILED")
        print("\n".join(f"- {failure}" for failure in failures))
        return 1
    print("GREEN/PASSED: Report 3 SRS is structurally valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
