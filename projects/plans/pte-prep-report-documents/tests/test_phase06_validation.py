"""RED/GREEN checks for the final cross-report validation handoff."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = next(parent for parent in Path(__file__).resolve().parents if parent.name == "pte-org")
TEST_ROOT = ROOT / "pte-doc" / "projects" / "plans" / "pte-prep-report-documents" / "tests"
REPORT_ROOT = ROOT / "pte-doc" / "report"
VALIDATION = REPORT_ROOT / "_validation" / "report-03-06-validation.md"


def main() -> int:
    failures: list[str] = []
    validator = TEST_ROOT / "validate_report_bundle.py"
    result = subprocess.run([sys.executable, str(validator)], cwd=ROOT, text=True, capture_output=True)
    if result.returncode != 0:
        failures.append("full report bundle validator failed: " + result.stdout.strip())
    if not VALIDATION.is_file():
        failures.append(f"missing final validation report: {VALIDATION}")
    else:
        text = VALIDATION.read_text(encoding="utf-8")
        for phrase in ["PASS", "Report 3", "Report 4", "Report 5", "Report 6", "onboarding", "delivery", "publication", "TBD"]:
            if phrase.lower() not in text.lower():
                failures.append(f"final validation report missing: {phrase}")
        if "BLOCK" in text and "BLOCK: 0" not in text:
            failures.append("final validation report contains an unresolved BLOCK finding")
    if failures:
        print("RED/FAILED")
        print("\n".join(f"- {failure}" for failure in failures))
        return 1
    print("GREEN/PASSED: cross-report validation is complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())

