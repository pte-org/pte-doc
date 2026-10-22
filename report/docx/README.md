# PTEPrep DOCX submission package

> **Status:** Current generated package for the English Report 3-6 Markdown baseline dated 22 October 2026. The four files include the revised scope, roles, Student practice requirements, channel flags, AI explanation boundaries and open-decision markers. Complete supervisor approval, DOCX visual inspection and final submission review remain separate gates.

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
