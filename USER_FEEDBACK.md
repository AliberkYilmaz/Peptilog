# User Feedback — Peptilog

Gathered issues from real-user testing (Aliberk + Arabella).
Status legend: 🟡 reported · 🟠 triaged · 🔵 scheduled · 🟢 fixed.

---

## #1 · 🟡 Calendar date tap doesn't pre-fill the Quick Log date

**Reporter:** Aliberk · 2026-05-07
**Where:** Calendar → tap a past date → Quick Log sheet
**Symptom:** Tapping a date on the calendar opens Quick Log, but the date/time field defaults to "now" instead of the tapped date. User saves without realizing → injection logged against today instead of the historical date intended.
**Concrete repro:** Aliberk tapped May 8 (when he started peptides), entered Tirzepatide 2.5mg SubQ ×2, hit save. Both entries got `2026-05-07 02:45/02:46 AM` (today) instead of May 8.
**Why it matters:** Backfilling old doses is broken. Friction is high — user has to manually re-enter a date they already chose.
**Suggested fix:** When Quick Log is opened from a calendar tap, pre-fill the date field with the tapped date (default time to current local time, or noon, or last-known time of day for that peptide). Only backfill date — keep time editable.

---

## #2 · 🟡 No way to delete or edit logged injections

**Reporter:** Arabella · 2026-05-07
**Where:** Day detail view → tap a logged injection
**Symptom:** Once an injection is saved, there's no UI to delete it or edit any of its fields (peptide, dose, route, date, time, notes). User is permanently stuck with whatever they entered, including duplicates and wrong-date entries.
**Why it matters:** Critical. Compounds with #1 — Aliberk's two Tirzepatide entries logged today (May 7) instead of May 8 cannot be removed. Any typo or accidental tap is permanent. Long-term retention killer; competitor reviews flag this as a top complaint elsewhere too.
**Suggested fix:** From the day detail view, tap a log entry → opens an edit sheet (same form as Quick Log, fields pre-filled). Add a delete action (long-press, swipe, or trash icon in the edit sheet). Confirmation dialog for delete. Soft-delete in Isar so cloud sync can replicate the deletion.

---

## #3 · 🟡 Official Peptilog logo not used as the launcher icon

**Reporter:** Aliberk · 2026-05-07
**Where:** Android launcher / app drawer
**Symptom:** App is using the default Flutter launcher icon (`@mipmap/ic_launcher`) instead of the official Peptilog logo. Aliberk uploaded the proper logo to Paperclip already.
**Scope:** Launcher icon only. Splash screen (animated circle) stays as-is.
**Suggested fix:** Pull the logo asset from Paperclip, run `flutter_launcher_icons` (or replace mipmap-* PNGs manually) for both Android and iOS, regenerate adaptive icons. Verify on launcher + recent apps screen.
