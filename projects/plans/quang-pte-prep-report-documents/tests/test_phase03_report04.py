"""RED/GREEN structural checks for the project-specific Report 4 design."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = next(parent for parent in Path(__file__).resolve().parents if parent.name == "pte-org")
REPORT = ROOT / "pte-doc" / "report" / "report04"
FILES = [
    "00-project-report.md",
    "00-record-of-changes.md",
    "01-system-design.md",
    "02-database-design.md",
    "03-detailed-design.md",
]


def main() -> int:
    failures: list[str] = []
    texts: dict[str, str] = {}
    for name in FILES:
        path = REPORT / name
        if not path.is_file():
            failures.append(f"missing Report 4 file: {path}")
            continue
        texts[name] = path.read_text(encoding="utf-8")
    combined = "\n".join(texts.values())
    for phrase in [
        "PTE Prep",
        "modular monolith",
        "PostgreSQL",
        "Redis",
        "RabbitMQ",
        "Cloudinary",
        "fixed exam",
        "tenant",
        "Current",
        "Planned/Future",
        "TBD",
        "EVD-",
    ]:
        if phrase.lower() not in combined.lower():
            failures.append(f"required Report 4 phrase missing: {phrase}")
    for identifier in ["FR-EXAM-004", "FR-DELIVERY-006", "FR-INTEGRITY-003", "FR-SCORE-005", "FR-REPORT-003", "NFR-09"]:
        if identifier not in combined:
            failures.append(f"Report 4 requirement link missing: {identifier}")
    for prefix in ["SD-", "PKG-", "DB-", "SEQ-", "ADR-"]:
        if prefix not in combined:
            failures.append(f"Report 4 design namespace missing: {prefix}")
    if "independent production microservice" in combined.lower() or "public microservice fleet" in combined.lower():
        failures.append("Report 4 must not document the backend as an independent production microservice fleet")
    if len(re.findall(r"\*\*Diagram ID:\*\*|\*\*Diagram ID\*\*|\*\*ERD ID:\*\*", combined)) < 3:
        failures.append("Report 4 has too few diagram metadata blocks")
    if "retry" not in combined.lower() or "idempot" not in combined.lower():
        failures.append("Report 4 does not describe retry/idempotency behavior")
    if "audit" not in combined.lower() or "publication" not in combined.lower():
        failures.append("Report 4 does not describe audit/publication design")
    if failures:
        print("RED/FAILED")
        print("\n".join(f"- {failure}" for failure in failures))
        return 1
    print("GREEN/PASSED: Report 4 design is structurally valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())

