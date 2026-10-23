# Known Issues and Blockers Tracker

This document tracks unresolved defects, environmental blockers, and third-party dependencies requiring manual credentials.

| ID | Issue Description | Severity | Area | Status | Workaround / Mitigation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **KI-001** | iOS Release Build Requires macOS & Xcode | Medium | Mobile (iOS) | Blocked by Environment | Linux development environment builds Android, Web, and Linux; iOS configuration is maintained in `ios/` and will be validated on macOS CI runner. |
| **KI-002** | Real-device SMS OTP Requires External Gateway | Low | Auth | Pending Setup | Supabase Auth supports email/password for local development and test automation. SMS provider credentials (e.g. Twilio) will be hooked in production environment without code changes. |
| **KI-003** | FCM Push Delivery Requires Google Services JSON | Low | Notifications | Pending Setup | In-app notification polling and database events are authoritative; push notification service uses safe graceful fallback when `google-services.json` is absent in local dev. |

---

*New issues must be added with severity, root cause analysis, and resolution plan.*
