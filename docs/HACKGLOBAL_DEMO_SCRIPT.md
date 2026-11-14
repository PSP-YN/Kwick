# HackGlobal 2026 — Kwick Demo Video Script

Target duration: 3 minutes. Record the actual application and dashboard. Do not use fabricated product screenshots or present seed data as live customers.

## Before recording

- Confirm the demo environment is connected to the intended Kwick Supabase project.
- Confirm the Gemini Edge Function is deployed and responds with a live assessment.
- Use dedicated demo accounts and clearly labelled demo requests.
- Ensure the admin account has the admin role.
- Remove browser tabs, notifications, API keys, service-role credentials, and personal data from the recording.
- If live AI is unavailable, disclose that and demonstrate the non-AI booking path; do not play back a canned result as if it were live.

## Narration and screen plan

### 0:00–0:20 — Opening

**On screen:** Kwick customer app landing screen.

**Say:**  
"Finding a home-service technician is not just a booking problem. Customers often do not know which trade they need, how urgent the issue is, or whether the person arriving is qualified. Kwick connects issue understanding, trusted dispatch, and accountable resolution in one workflow."

### 0:20–0:55 — Customer issue and AI triage

**On screen:** Create a plumbing request and enter a realistic demo issue such as a leaking kitchen sink. Run Kwick Intelligence.

**Say:**  
"Instead of asking customers to guess the technical category, Kwick can assess a plain-language description. The AI returns a suggested trade, urgency, a concise summary, safety alerts, and follow-up questions. This is advisory guidance, not a professional diagnosis. The customer reviews it and remains in control."

**Show:** Suggested category, urgency, safety alerts, follow-up questions, and the option to apply the suggested category.

### 0:55–1:20 — Customer booking

**On screen:** Enter a demo service address and submit the request. Open the order detail screen.

**Say:**  
"The customer can submit the request with or without AI. The triage summary and dispatcher note are carried into the operations workflow, so the team receives more useful context before dispatch."

### 1:20–2:00 — Operations and trust-aware dispatch

**On screen:** Sign in to the operations console. Open the dispatch queue, select the request, inspect eligible providers, and assign a demo provider.

**Say:**  
"Operations staff review requests and assign a technician. Kwick enforces the important trust constraints: the provider must be approved, available, qualified for the requested trade, and registered for the service area. Candidate ranking uses visible signals such as rating, completed jobs, and experience."

### 2:00–2:30 — Provider lifecycle

**On screen:** Switch to the provider account. Accept the offered job and progress the status through the available workflow.

**Say:**  
"The provider sees only their authorised work. Assignment responses and job progress are recorded through transactional database functions, rather than unrestricted client-side status updates."

### 2:30–2:50 — Engineering and safety

**On screen:** Show a prepared architecture diagram and the security documentation, not secrets or raw customer data.

**Say:**  
"The system uses Flutter, Supabase Auth, PostgreSQL row-level security, transactional RPCs, and a protected Next.js operations console. The Gemini key stays server-side. AI cannot book, dispatch, set prices, or change job status."

### 2:50–3:00 — Close

**On screen:** Kwick logo and tagline.

**Say:**  
"Kwick: Diagnose. Match. Resolve. Better information before dispatch, and accountability through resolution."

## Recording checklist

- [ ] Real customer journey recorded end-to-end.
- [ ] AI output visibly returned by the deployed Edge Function, or clearly disclosed as unavailable.
- [ ] Customer approval and booking are visible.
- [ ] Admin assignment is visible.
- [ ] Provider acceptance and status progression are visible.
- [ ] No secrets, private user data, or real customer addresses are visible.
- [ ] No invented adoption, revenue, accuracy, or impact statistics are spoken.
- [ ] Final video link is accessible without a login.
