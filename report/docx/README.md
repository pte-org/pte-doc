# PTEPrep DOCX submission package

> **Status:** Generated English Report 3-6 package dated 22 October 2026, preceding the subsequent user decision confirmations noted below. The files include revised scope, roles, Student practice, channel flags and AI boundaries. Regeneration against the updated Markdown, visual inspection and final submission review remain pending.

Decision follow-up on 22 October 2026: the user subsequently confirmed D01-D03 and Practice language/feedback policy. Those confirmations have been applied to Markdown; these DOCX copies precede that follow-up and require regeneration before submission against the updated decisions. See [confirmed decisions](../../projects/plans/quang-pte-practice-completion/decisions.md).

These DOCX files are generated from the supplied Report 3-6 Word templates. The generated documents preserve the template cover/logo, page settings, Word theme, heading hierarchy, table styling, and table-of-contents control while replacing the generic sample body with the current PTEPrep report content.

## Files

- `FA26SE182_Report3_PTE-Prep_Software-Requirement-Specification.docx`
- `FA26SE182_Report4_PTE-Prep_Software-Design-Document.docx`
- `FA26SE182_Report5_PTE-Prep_Software-Test-Documentation.docx`
- `FA26SE182_Report6_PTE-Prep_Software-User-Guides.docx`

The DOCX package keeps the heading outline current. Cached page numbers are intentionally omitted from the generated outline so that a submission does not contain stale page references; Microsoft Word can add them after the document layout is finalized.

## Regeneration

From `D:\GitHub\pte-org`:

```powershell
python .\pte-doc\tools\generate_report_docx.py
```

The source templates under `template-doc` are read-only inputs for this generator and are not overwritten.
