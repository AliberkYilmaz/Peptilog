# PEPTILOG — Product Specification

> Last updated: 2026-04-23
> Status: Pre-development
> Version: 2.0

---

## 1. Product Overview

**Peptilog** is a mobile app for tracking peptide injections, weight, health metrics, and dosing calculations. It is designed for individuals who self-administer peptides and want a fast, visual, and reliable way to manage their protocol.

| Parameter | Decision |
|-----------|----------|
| App Name | Peptilog |
| Platforms | iOS + Android (App Store + Play Store) |
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Local Database | Isar |
| Cloud Database | Supabase (PostgreSQL) |
| Auth | Supabase Auth (Apple + Google + Email/Password) |
| Cloud Storage | Supabase Storage |
| Theme | "Warm Ink + Serif" — dark editorial, amber accent `#E8A84C` |
| Design Tool | GPT Image Gen (wireframes, design system, app icon, onboarding) |
| Dev Tool | Paperclip.ing (AI agent orchestration) |
| Monetization | TBD — infrastructure will support freemium, decided post-launch |
| Target Audience | Peptide users worldwide |

---

## 2. Authentication & Security

### 2.1 Auth Flow (First Launch)
1. Welcome/onboarding screens (3 slides)
2. Sign up / Sign in:
   - **Apple Sign-In** (required by App Store policy)
   - **Google Sign-In**
   - **Email + Password**
3. PIN setup (4-6 digit)
4. Optional: Biometric setup (Face ID / Touch ID)
5. Profile setup (name, optional)
6. Land on Calendar (home screen)

### 2.2 Returning User Flow
1. App opens → Biometric prompt (if enabled) OR PIN entry
2. Land on Calendar

### 2.3 Security Layers
| Layer | Purpose |
|-------|---------|
| Supabase Auth | Account identity, cloud data access |
| PIN (4-6 digit) | Quick local unlock, privacy protection |
| Biometrics | Face ID / Touch ID, convenience layer on top of PIN |

PIN and biometric are **local-only** — they don't touch the server. Similar to banking apps (GCash model).

### 2.4 Data Privacy
- Health data requires explicit user consent
- GDPR: Right to deletion — user can delete all data from Settings
- KVKK (Turkey): Same as GDPR
- Medical disclaimer: "This app is not a medical device and does not provide medical advice"
- Privacy Policy: Required, must be hosted on a public URL before App Store submission

---

## 3. Feature Set

### 3.1 Core Features (MVP)

| Feature | Description | Priority |
|---------|-------------|----------|
| Quick Log | Log injection in <5 seconds: select peptide, dose, route, save | P0 |
| Calendar View | Month view with colored dots per peptide per day | P0 |
| Day Detail | Tap a date to see all logs for that day | P0 |
| Peptide Master List | Preset peptides + user can add/edit/delete custom peptides | P0 |
| Local Reminders | Scheduled notifications that deep-link to Quick Log | P0 |
| Weight Tracker | Daily weight entry, 30-day line graph with goal line | P1 |
| Peptide Calculator | Convert mg dose to syringe units based on reconstitution volume | P1 |
| CSV Export | Export all logs to CSV file for backup | P2 |
| PIN Lock | 4-6 digit PIN on app launch | P0 |
| Biometric Auth | Face ID / Touch ID | P1 |
| Cloud Sync | Isar ↔ Supabase automatic sync | P1 |

### 3.2 Extended Features (Post-MVP, all included in roadmap)

| Feature | Description | Priority |
|---------|-------------|----------|
| Order Calculator | Vial quantity planning — how many vials to order based on protocol | P2 |
| Sleep Tracking | Log sleep hours per night, trend graph | P2 |
| Blood Pressure | Systolic/diastolic/pulse logging | P2 |
| Advanced Analytics | Trends, correlations (e.g. weight vs peptide usage), streaks | P3 |
| Multi-device Sync | Seamless data across devices via Supabase | P1 (comes with cloud sync) |

---

## 4. User Flows

### 4.1 Daily Logging (Primary Flow)
```
Open app → Biometric/PIN → Calendar view
  → Tap "+" FAB
  → Quick Log screen:
     - Select peptide (color chip)
     - Enter dose (mg)
     - Select route (SubQ / IM)
     - Optional: notes
  → Tap Save
  → Auto-timestamp → return to Calendar
  → Colored dot appears on today's date
```

### 4.2 Weight Tracking
```
Tap Weight tab → View 30-day graph
  → Tap "+ Add Weight" → enter kg → Save
  → Graph updates immediately
```

### 4.3 Reminder Flow
```
Tools tab → Reminders → Create:
  - Select peptide
  - Select days (Mon, Wed, Fri, etc.)
  - Select time
→ Notification fires: "Peptide scheduled"
→ Tap notification → deep link to Quick Log
```

### 4.4 Calculator Flow
```
Tools tab → Calculator:
  - Select peptide
  - Enter total mg in vial
  - Enter reconstitution volume (mL)
  - Enter desired dose (mg)
→ Result: X units on U-100 syringe
→ "Save to Log" button → pre-fills Quick Log
```

### 4.5 Sleep Tracking
```
Health tab → Sleep:
  - Enter hours slept
  - Optional: quality rating (1-5)
→ 30-day trend graph
```

### 4.6 Blood Pressure
```
Health tab → Blood Pressure:
  - Enter systolic / diastolic / pulse
→ Trend graph with normal range overlay
```

---

## 5. Navigation Structure

Bottom tab bar with 5 tabs:

| Tab | Icon | Content |
|-----|------|---------|
| Calendar | Calendar icon | Month view with colored dots, day detail on tap |
| Log | Plus icon | Quick Log form (also via FAB on Calendar) |
| Weight | Scale icon | 30-day graph + add weight |
| Health | Heart icon | Sleep tracking + Blood pressure |
| Profile | Person icon | Settings, PIN, CSV export, account, reminders |

Tools (Calculator, Reminders, Order Calculator) accessible from Profile or dedicated section.

---

## 6. Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Flutter (Dart) | Single codebase iOS + Android |
| State Management | Riverpod | Compile-safe, testable, recommended for production |
| Local DB | Isar | Flutter-native, extremely fast, offline-first, Dart objects |
| Cloud DB | Supabase (PostgreSQL) | Open-source, RLS for data isolation, auth built-in |
| Auth | Supabase Auth | Apple + Google + Email, handles tokens and sessions |
| Charts | fl_chart | Customizable line/bar charts for weight, BP, sleep |
| Calendar | table_calendar | Month view with custom dot markers |
| Notifications | flutter_local_notifications | Local scheduled reminders |
| CSV | csv + share_plus | Generate CSV and share via system sheet |
| Security | flutter_secure_storage | PIN hash, biometric flags |
| Biometrics | local_auth | Face ID / Touch ID |
| Cloud Storage | Supabase Storage | Profile photos, future attachments |

---

## 7. Database Schema

### 7.1 Isar Collections (Local)

```dart
@collection
class Peptide {
  Id id = Isar.autoIncrement;
  late String name;          // e.g., "Tirzepatide"
  late String color;         // Hex, e.g., "#7B61FF"
  late String unit;          // "mg"
  bool isActive = true;
  bool isCustom = false;     // true if user-added
  String? supabaseId;        // UUID from Supabase, null if not synced
  DateTime updatedAt = DateTime.now();
}

@collection
class InjectionLog {
  Id id = Isar.autoIncrement;
  late int peptideId;        // Isar peptide ID
  late double doseMg;
  late String route;         // "SubQ" or "IM"
  double? units;             // Syringe units (calculated)
  String? notes;
  late DateTime loggedAt;    // User-set or auto
  DateTime createdAt = DateTime.now();
  String? supabaseId;
  DateTime updatedAt = DateTime.now();
  bool isDeleted = false;    // Soft delete for sync
}

@collection
class WeightLog {
  Id id = Isar.autoIncrement;
  late double weightKg;
  late DateTime date;        // One entry per day
  DateTime createdAt = DateTime.now();
  String? supabaseId;
  DateTime updatedAt = DateTime.now();
  bool isDeleted = false;
}

@collection
class SleepLog {
  Id id = Isar.autoIncrement;
  late double hours;
  int? qualityRating;        // 1-5, optional
  late DateTime date;
  DateTime createdAt = DateTime.now();
  String? supabaseId;
  DateTime updatedAt = DateTime.now();
  bool isDeleted = false;
}

@collection
class BloodPressureLog {
  Id id = Isar.autoIncrement;
  late int systolic;
  late int diastolic;
  int? pulse;
  late DateTime measuredAt;
  DateTime createdAt = DateTime.now();
  String? supabaseId;
  DateTime updatedAt = DateTime.now();
  bool isDeleted = false;
}

@collection
class Reminder {
  Id id = Isar.autoIncrement;
  late int peptideId;
  late String daysOfWeek;    // "Mon,Wed,Fri"
  late String time;          // "HH:MM"
  bool isActive = true;
  int? notificationId;       // Platform notification ID
  String? supabaseId;
  DateTime updatedAt = DateTime.now();
}
```

### 7.2 Supabase Tables (Cloud)

Mirror of Isar collections with these additions:
- `id` → UUID (primary key)
- `user_id` → UUID (foreign key to auth.users, for RLS)
- All tables have Row Level Security: users can only read/write their own data

```sql
-- Example: injection_logs table
CREATE TABLE injection_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  peptide_id UUID REFERENCES peptides(id),
  dose_mg DECIMAL NOT NULL,
  route TEXT NOT NULL CHECK (route IN ('SubQ', 'IM')),
  units DECIMAL,
  notes TEXT,
  logged_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  is_deleted BOOLEAN DEFAULT false
);

ALTER TABLE injection_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access own data"
  ON injection_logs FOR ALL
  USING (auth.uid() = user_id);
```

Same pattern for all tables: `peptides`, `weight_logs`, `sleep_logs`, `blood_pressure_logs`, `reminders`.

---

## 8. Sync Strategy (Isar ↔ Supabase)

### 8.1 Principles
- **Offline-first**: All writes go to Isar first, always
- **Eventual consistency**: Sync to Supabase when internet is available
- **Conflict resolution**: Last-write-wins based on `updatedAt` timestamp
- **Soft deletes**: `isDeleted = true` instead of actual deletion, so deletes can sync

### 8.2 Sync Flow

```
User Action
  → Write to Isar (immediate, offline)
  → Mark record as "dirty" (needs sync)
  → SyncService checks connectivity
    → If online:
       → Push dirty records to Supabase (upsert)
       → Pull new/updated records from Supabase (since last sync)
       → Update Isar with pulled data
       → Clear dirty flags
    → If offline:
       → Queue for later, retry on connectivity change
```

### 8.3 Sync Triggers
1. **On write**: After every local write, attempt sync
2. **On app resume**: Sync when app comes to foreground
3. **On connectivity change**: Sync when internet becomes available
4. **Periodic**: Background sync every 15 minutes (if app is active)

### 8.4 Conflict Resolution
- Each record has `updatedAt` timestamp
- On conflict: **last-write-wins** — the record with the latest `updatedAt` is kept
- Edge case: if same record modified on two devices offline, the one that syncs last wins
- For MVP this is acceptable — advanced conflict resolution (CRDT) is overkill

### 8.5 First Login on New Device
- User signs in → Pull all data from Supabase → Populate Isar
- Subsequent syncs are incremental (only changes since last sync)

---

## 9. Peptide Master List

### 9.1 Preset Peptides (Seeded)

| Name | Color | Unit |
|------|-------|------|
| Tirzepatide | `#7B61FF` | mg |
| GHK-Cu | `#3A86FF` | mg |
| NAD+ | `#2EC4B6` | mg |
| Retatrutide | `#FB5607` | mg |
| Tesamorelin | `#FFBE0B` | mg |

### 9.2 Custom Peptides
Users can:
- Add new peptides (name, color picker, unit)
- Edit existing peptides (including presets)
- Delete/hide peptides (soft delete, data preserved)
- Reorder peptides

Custom peptides sync to cloud. Preset peptides exist locally by default and sync on first cloud connection.

---

## 10. Peptide Calculator

### 10.1 Formula
```
Units = (Desired Dose mg / Total mg in Vial) × (Reconstitution Volume mL × 100)
```

U-100 syringe: 1 mL = 100 units. Always round to nearest whole unit.

### 10.2 Example
- Vial: 10 mg Tirzepatide
- Reconstituted with: 2 mL bacteriostatic water
- Desired dose: 2.5 mg
- Calculation: (2.5 / 10) × (2 × 100) = 50 units

### 10.3 Calculator Inputs
| Input | Type | Validation |
|-------|------|-----------|
| Peptide | Dropdown | From master list |
| Total mg in vial | Number | > 0 |
| Reconstitution volume (mL) | Number | > 0 |
| Desired dose (mg) | Number | > 0, ≤ total mg |

Output: syringe units (rounded). **"Save to Log"** button pre-fills Quick Log.

---

## 11. Order Calculator

Calculates how many vials to order based on protocol.

### 11.1 Inputs
| Input | Type |
|-------|------|
| Peptide | Dropdown |
| Dose per injection (mg) | Number |
| Injections per week | Number |
| Weeks of supply needed | Number |
| mg per vial | Number |

### 11.2 Output
```
Total mg needed = dose × injections/week × weeks
Vials needed = ceil(total mg / mg per vial)
```

Always round up (can't buy partial vials).

---

## 12. Performance Targets

| Metric | Target |
|--------|--------|
| Calendar load | < 300 ms |
| Quick Log save | < 150 ms |
| Graph render | < 500 ms |
| Network dependency | None (offline-first) |
| Crash rate | 0 in normal flow |
| Sync latency | < 3 seconds when online |

---

## 13. Development Roadmap

### Phase 0: Project Setup (1 day)
- Flutter project creation (`com.peptilog.app`)
- Folder structure (feature-first)
- Riverpod + Isar + Supabase packages
- Supabase project creation + schema
- GitHub repo setup
- CI/CD skeleton

### Phase 1: Auth & Security (2 days)
- Supabase Auth integration (Apple + Google + Email)
- PIN setup & entry screens
- Biometric auth (Face ID / Touch ID)
- Secure storage for PIN hash

### Phase 2: Data Layer (2 days)
- Isar collections (all models)
- Repository pattern (abstract → Isar implementation)
- Seed peptide master list
- Supabase tables + RLS policies

### Phase 3: Quick Log (2 days)
- Log form: peptide selector, dose input, route toggle
- Auto-timestamp with manual edit option
- Save to Isar
- Notes field (optional)

### Phase 4: Calendar (3 days)
- Month view with colored dots per peptide
- Tap date → day detail view (all logs, newest first)
- Swipe between months

### Phase 5: Sync Engine (3 days)
- SyncService: dirty tracking, push/pull
- Connectivity monitoring
- Conflict resolution (last-write-wins)
- First-device-setup: pull all from cloud

### Phase 6: Weight Tracker (2 days)
- Weight entry form (kg, one per day)
- 30-day line graph with goal line
- Graph updates on save

### Phase 7: Reminders (2 days)
- Create/edit/delete reminders
- Local notification scheduling
- Deep link: notification tap → Quick Log
- Notification permission handling

### Phase 8: Peptide Calculator (1 day)
- Calculator UI and formula
- "Save to Log" integration

### Phase 9: Health Metrics (3 days)
- Sleep tracking (hours + quality)
- Blood pressure (systolic/diastolic/pulse)
- Trend graphs for both
- Normal range overlays

### Phase 10: Order Calculator (1 day)
- Order calculator UI and formula
- Round-up logic

### Phase 11: Analytics (3 days)
- Usage streaks
- Weight vs peptide correlation
- Adherence rate
- Exportable reports

### Phase 12: Export & Polish (2 days)
- CSV export (all data types)
- Account deletion (GDPR)
- App icon
- Final UI polish
- Bug fixes

### Phase 13: App Store Prep (2 days)
- Screenshots (iPhone, iPad, Android)
- App Store description + keywords (ASO)
- Privacy Policy page (hosted)
- Terms of Service
- Medical disclaimer
- TestFlight / Internal Testing distribution
- Submit for review

**Estimated total: 4-6 weeks**

---

## 14. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| App Store rejection (health category) | High | Frame as "personal tracker", add medical disclaimer, avoid "medical device" language |
| Apple Sign-In requirement | Blocker | Include Apple Sign-In from day 1 |
| Notification reliability (iOS) | Medium | Test on physical devices, handle permission denial gracefully |
| Sync conflicts | Medium | Last-write-wins + `updatedAt` timestamps |
| Data loss | High | Cloud sync is primary backup, CSV export as secondary |
| Supabase costs | Low | Free tier: 500MB DB, 1GB storage, 50K monthly active users — more than enough for launch |
| Peptide legality concerns | Medium | App tracks usage only, doesn't sell/recommend. Disclaimer covers this |

---

## 15. App Store Information

| Field | Value |
|-------|-------|
| App Name | Peptilog |
| Bundle ID | `com.peptilog.app` |
| Category | Health & Fitness |
| Content Rating | 12+ (medical/health info) |
| Price | TBD (free with potential premium features later) |
| Supported Languages | English (launch), Turkish (post-launch) |
| Minimum iOS | 15.0 |
| Minimum Android | API 26 (Android 8.0) |

---

## 16. Design Direction — "Warm Ink + Serif"

**Design Philosophy:** Dark editorial warmth — like a leather-bound journal with typeset pages. Inspired by Arc Browser's calm confidence. Premium, restrained, never overwhelming.

**Keywords:** Güven, huzur, sadelik, netlik, anlaşılırlık, pratiklik.

### 16.1 Color Palette
| Token | Dark Mode | Light Mode | Usage |
|-------|-----------|------------|-------|
| Amber (Accent) | `#E8A84C` | `#E8A84C` | CTA buttons, important numbers, active nav, chart lines |
| Background | `#1C1C1E` | `#F7F5F2` | App background |
| Surface | `#2C2C2E` | `#FFFFFF` | Cards, input fields, elevated surfaces |
| Text | `#F5F0E8` | `#2D2A27` | Primary text |
| Muted Text | `#8A8A8A` | `#9A9590` | Secondary text, timestamps, labels |
| Success | `#7EC699` | `#5B8C5A` | Positive changes (weight loss, streaks) |
| Warning | `#E8A84C` | `#E8A84C` | Same as accent |
| Error | `#D4634A` | `#D4634A` | Destructive actions, alerts |

> **Dark mode:** Warm ink black, cream text — book by candlelight.
> **Light mode:** Warm parchment, ink text, subtle warm shadows — Moleskine in sunlight.
> **Amber stays constant** across both modes for brand consistency.

### 16.2 Typography
| Level | Font | Weight | Size |
|-------|------|--------|------|
| Headers | Source Serif 4 | Semibold (600) | 20-36px |
| Body | Inter | Regular (400) | 15px |
| Labels | Inter | Regular (400) | 11px uppercase, tracking-wide |
| Captions | Inter | Regular (400) | 13px |
| Large Numbers | Source Serif 4 | Bold (700) | 36px |

### 16.3 Component Style
- **Cards:** `#2C2C2E` on `#1C1C1E`, no borders, 12px rounded corners, generous padding
- **Buttons (Primary):** Amber `#E8A84C` fill, dark text, fully rounded
- **Buttons (Secondary):** `#3C3C3E` fill, gray text
- **Inputs:** `#2C2C2E` surface, no borders, labels in uppercase Inter
- **Bottom Nav:** Thin monoline icons, muted cream default, amber active
- **Toggle/Pills:** Selected = amber with dark text, unselected = `#3C3C3E` with gray text
- **Lists:** No dividers, surface color separation, serif for item names, Inter for metadata

### 16.4 Design Assets (GPT Image Gen)
- [x] Design system UI kit
- [x] App icon / logo — Geometric vial, amber outline on dark, tilted ~12°
- [x] Screen mockups: Dashboard, Log Injection, History, Progress/Stats (dark mode)
- [x] Onboarding screens (3 slides)
- [ ] App Store screenshots

---

## 17. Test Strategy

### 17.1 Test Pyramid
| Level | Tool | Coverage Target | What to Test |
|-------|------|----------------|--------------|
| Unit | `flutter_test` | 80%+ | Business logic, calculator formulas, validation, sync logic |
| Widget | `flutter_test` | Key screens | UI renders correctly, user interactions work |
| Integration | `integration_test` | Critical flows | Quick Log → save → calendar dot appears, auth flow |

### 17.2 CI Test Rules
- All tests must pass before merge to `main`
- Calculator formula tests are **mandatory** (health-critical math)
- Sync logic must have offline/online scenario tests

---

## 18. CI/CD Pipeline

### 18.1 GitHub Actions Workflow
```
On PR to main:
  → Lint (dart analyze)
  → Format check (dart format)
  → Run unit + widget tests
  → Build APK (Android) — verify no build errors
  → Build IPA (iOS) — verify no build errors

On merge to main:
  → All above +
  → Build release APK → upload to Play Store Internal Testing
  → Build release IPA → upload to TestFlight
  → Tag version (semantic versioning)
```

### 18.2 Environments
| Environment | Purpose | Database |
|-------------|---------|----------|
| `dev` | Local development | Local Isar + Supabase dev project |
| `staging` | TestFlight / Internal Testing | Supabase staging project |
| `prod` | App Store / Play Store | Supabase production project |

---

## 19. Error Handling

### 19.1 User-Facing Errors
| Scenario | User Sees | Behavior |
|----------|-----------|----------|
| Sync fails | Subtle banner: "Offline — data saved locally" | Auto-retry on connectivity change |
| Sync conflict | Silent (last-write-wins) | No user action needed |
| Invalid input | Inline field error (red text below input) | Prevent save until fixed |
| Auth session expired | "Session expired, please sign in again" | Redirect to login |
| Network timeout | Toast: "Connection timed out" | Data stays in local DB |
| Crash | Crash report sent to Sentry (auto) | App restarts normally |

### 19.2 Retry Policy
- Sync: Exponential backoff — 1s, 2s, 4s, 8s, max 60s, then wait for connectivity change
- Auth: Single retry, then prompt re-login
- Never retry in a tight loop

---

## 20. Localization

### 20.1 Setup
- Use `flutter_localizations` + ARB files from day 1
- All user-facing strings in ARB files, never hardcoded
- Initial languages: **English** (launch), **Turkish** (post-launch)

### 20.2 File Structure
```
lib/l10n/
  app_en.arb    ← English (default)
  app_tr.arb    ← Turkish
```

### 20.3 Rules
- ARB keys use camelCase: `quickLogTitle`, `saveButton`
- Plurals and gender handled via ARB ICU syntax
- Date/time formatting via `intl` package, respects device locale

---

## 21. Analytics & Crash Reporting

### 21.1 Crash Reporting
- **Sentry** (`sentry_flutter`) — crash reports, breadcrumbs, performance monitoring
- All uncaught exceptions auto-reported
- Include device info, OS version, app version

### 21.2 Analytics (Privacy-Friendly)
- **PostHog** (open-source, self-hostable) OR **Supabase Analytics**
- Track: screen views, feature usage (which tabs, calculator usage), retention
- **Do NOT track**: actual health data, doses, weights, personal info
- Users can opt out in Settings
- No third-party ad tracking

---

## 22. Accessibility

### 22.1 Requirements
- All interactive elements have **semantic labels** (for VoiceOver / TalkBack)
- Minimum contrast ratio **4.5:1** for text (WCAG AA)
- Touch targets minimum **44x44 pt**
- Charts have text alternatives (e.g. "Weight trend: 78.2 kg, down 1.3 kg this month")
- Support **dynamic type** / font scaling
- Respect **prefers-reduced-motion** for animations

### 22.2 Testing
- Test with VoiceOver (iOS) and TalkBack (Android) on physical devices
- Use Flutter's `Semantics` widget for custom labels

---

## 23. Versioning & Migration

### 23.1 App Versioning
- Semantic versioning: `MAJOR.MINOR.PATCH` (e.g. 1.0.0)
- Major: breaking changes, major new features
- Minor: new features, non-breaking
- Patch: bug fixes

### 23.2 Database Migration
- Isar: schema changes handled via Isar's built-in migration
- Supabase: SQL migration files in `supabase/migrations/` directory
- Every schema change = new migration file, never edit existing ones

### 23.3 Force Update
- Store minimum supported version in Supabase `app_config` table
- On app launch: check `min_version` → if current < min, show "Update Required" screen
- Use only for breaking backend changes

---

## 24. User Feedback & Support

### 24.1 In-App
- Settings → "Send Feedback" → opens email compose to `support@peptilog.com`
- Include automatic device info (OS, app version, device model) in email body
- Optional: in-app shake-to-report (attach screenshot)

### 24.2 External
- App Store / Play Store reviews — monitor weekly
- Support email: `support@peptilog.com`

---

## 25. Deep Linking

### 25.1 URI Scheme
```
peptilog://                    → Open app (calendar)
peptilog://log/new             → Open Quick Log
peptilog://weight/add          → Open weight entry
peptilog://reminder/:id        → Open specific reminder
```

### 25.2 Usage
- Notifications deep-link to `peptilog://log/new`
- Future: share protocol links, universal links for web
