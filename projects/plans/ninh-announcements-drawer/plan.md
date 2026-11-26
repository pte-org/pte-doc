# Announcements list + detail drawer (vendor-web /admin/announcements)

- Table: "Updated" as `19:23 · 26/11/2026`; importance and status as pill badges; a draft shows a dash in "Recipients" (the API sends zero counts for a draft, which read as "0/0"). The title is a button that opens the drawer; "View" in the row menu does the same.
- Drawer (right, common Drawer): title + "Published/Updated <time>", importance and status badges, the message in a grey box, "Delivery result" (sent n/m with %, progress bar, waiting / failed / skipped / read) for a published one, or "Eligible organizations" for a draft, general info (category, affected from/until, updated). Footer by state: draft = Delete draft / Edit / Publish; published = Retry failed deliveries (only when some failed) / Close.
- The drawer steps aside while a confirmation dialog is open (the drawer sits above dialogs) and returns on cancel; edit closes it and opens the form.
- The hand-rolled confirm overlay in the list became the common ConfirmDialog. Columns moved to useAnnouncementColumns, the drawer is AnnouncementDrawer (the list file is back under 300 lines).
- Removed the now-dead detail route /admin/announcements/[publicId] with AnnouncementDetailView, AnnouncementInlineForm and the useAnnouncementQuery hook (nothing else linked or imported them).
- Drawer polish: a rule above "General information"; "Read" shows as read / delivered (%).
