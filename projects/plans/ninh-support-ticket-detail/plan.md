# Support ticket detail page (tenant-web)

Status: done (UI only, no API change)

- Header: PageHeader "Yeu cau #ID", status badge + "Gui luc HH:mm · dd/MM/yyyy" below, "Dong yeu cau" (OPEN only, reuses useCloseTicket + ConfirmDialog).
- Two columns (lg): left = "Noi dung yeu cau" card (pre-wrap) + "Phan hoi tu quan tri vien" card; right = "Thong tin yeu cau" (status, category, copyable ID, sent, last updated).
- Admin reply = message block (role + time); empty state with icon + hint.
- OPEN badge is now info (blue) via STATUS_VARIANTS, so the list matches too.
- Time without seconds: utils/formatTicketTime.ts.
- Submitter name: SupportTicketResponse.submitterName (null if the account is gone), resolved in SupportTicketService via IdentityService.findFullNames; the info card hides the row when null.
- Not done: multi-turn replies / attachments (backend has admin notes only).
