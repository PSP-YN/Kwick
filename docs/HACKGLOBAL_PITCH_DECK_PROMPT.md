# HackGlobal Pitch Deck Prompt — NexHelp

Use this prompt in Gamma or another presentation generator. Generate a polished, judge-focused 10-slide presentation in 16:9 format.

---

## Master prompt

Create a premium startup/hackathon pitch deck for **NexHelp — Diagnose. Match. Resolve.**, a trust-first home-services platform with AI-assisted issue triage and accountable technician dispatch.

### Audience and objective
The audience is an international hackathon judging panel evaluating originality, technical execution, real-world impact, feasibility, product quality, and entrepreneurial potential. The deck must explain the problem quickly, demonstrate a working product journey, and make the technical differentiators credible.

### Visual direction
- Premium product-company aesthetic, not a generic AI pitch template.
- Palette: charcoal/near-black, warm amber/orange accents, clean off-white, restrained neutral grays.
- Strong typography, generous whitespace, precise alignment, clear hierarchy.
- Use product UI screenshots and architecture diagrams where available.
- Use real interface screenshots from the repository/demo when supplied; do not invent screens and present them as implemented.
- Use simple vector diagrams for the workflow, database security, and system architecture.
- Avoid purple/blue gradients, robot illustrations, glowing brains, generic stock photos, and decorative circuit patterns.
- Keep each slide to one central argument and concise text.
- Use diagrams and annotated product screenshots instead of paragraphs.

### Accuracy constraints
- Do not invent users, revenue, adoption, customer testimonials, partnerships, model accuracy, cost savings, or measured impact.
- Distinguish implemented features from planned features.
- Label any demo records as demo data.
- Describe AI output as advisory triage, not a professional diagnosis.
- State that the customer remains in control and can submit a booking without AI.
- Do not claim a live AI deployment unless the Gemini function is deployed and tested.

## Slide-by-slide structure

### 1. Cover — Diagnose. Match. Resolve.
Project name, concise tagline, primary track: Open Innovation. Show a polished customer booking screen or a clear product mockup derived from the real app.

### 2. The problem — Booking a technician is still a trust and information problem
Explain the customer uncertainty: wrong trade, unclear urgency, incomplete issue details, unknown provider quality, and no accountable service journey. Use one concrete household scenario rather than unsupported market statistics.

### 3. The solution — One traceable service journey
Show the journey: describe issue → AI triage → customer confirms → verified provider match → dispatch → job progress → review. Make the user-control point visible.

### 4. Product walkthrough — From a leaking sink to an accountable booking
Use actual product screenshots. Annotate the AI issue summary, urgency, safety alerts, follow-up questions, and booking confirmation. Clearly label any missing live integration.

### 5. NexHelp Intelligence — Structured triage, not an unrestricted chatbot
Show the structured output: suggested trade, urgency, summary, safety alerts, questions, dispatcher note, and model confidence. Explain the guardrails: no repair instructions, price promises, or autonomous booking.

### 6. Trust-aware dispatch — The right provider, not just the nearest name
Show the matching constraints: approved verification status, active trade category, available status, one active assignment per provider, and service-area eligibility. Explain transparent ranking signals: published rating, completed jobs, and experience.

### 7. Engineering architecture — Secure by design
Diagram Flutter app → Supabase Auth → Edge Function → Gemini API; and Flutter/Admin → PostgreSQL with RLS, column-level privileges, transactional RPCs, and audit events. Show that the Gemini key stays server-side.

### 8. What makes it defensible
Focus on the combination of issue triage, trust-aware dispatch, operational state transitions, and auditability. Explain why this is more than a chatbot attached to a booking form.

### 9. Impact and business model
Show the impact hypotheses and how they will be measured: misrouted request rate, time from request to assignment, provider acceptance rate, completion rate, repeat usage, and dispute rate. Present a plausible local pilot and potential SaaS/marketplace revenue model without inventing results.

### 10. Roadmap and close
Show the next steps: deploy a real Bengaluru pilot, onboard verified technicians, collect consented feedback, evaluate triage quality, expand service categories and regions. Close with: **NexHelp — Better information before dispatch. Accountability through resolution.**

### Output requirements
- 10 slides, 16:9.
- Short titles and concise body copy.
- Include speaker notes with a 20–30 second explanation per slide.
- Keep all claims traceable to the repository or clearly labelled as hypotheses.
- Export-ready for a 3–4 minute pitch.
