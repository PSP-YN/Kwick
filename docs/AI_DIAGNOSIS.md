# NexHelp Intelligence — AI Issue Triage

## Purpose

NexHelp Intelligence helps a customer describe a home-service problem and gives the dispatcher a structured, cautious first-pass assessment before assignment. It is decision support, not a professional diagnosis.

## Request flow

1. The authenticated Flutter app sends the issue description and optional category hint to the `diagnose-service` Supabase Edge Function.
2. The function validates the caller with Supabase Auth.
3. A private usage table enforces a limit of five assessments per user per hour.
4. The function sends only the issue description and category hint to Gemini. It does not send the customer's name, phone number, email, or service address.
5. Gemini returns a schema-constrained assessment: suggested category, urgency, summary, safety alerts, follow-up questions, dispatcher note, and model-reported confidence.
6. The function validates the response and returns it to the app.
7. The customer may submit the booking with the AI summary attached to the dispatcher notes. The customer can also book without AI.

## Safety boundaries

- No repair instructions, price promises, provider availability claims, or medical advice.
- Emergency urgency is reserved for immediate hazards such as fire, smoke, electric shock, exposed live wiring, gas smell, major flooding, or immediate risk to life.
- Safety alerts are conservative. Users should stay away from hazards and contact local emergency services or the relevant utility when appropriate.
- AI suggestions never change the selected category automatically; the customer can explicitly apply a supported suggestion. Booking submission always requires customer action.
- The customer-facing UI labels the output advisory and discloses that issue text is sent to Gemini.
- Users are instructed not to include names, phone numbers, or addresses in the issue description.

## Privacy and quota

- The Gemini API key is stored as a Supabase Edge Function secret, never in the mobile app or repository.
- The function writes only user ID, model ID, and timestamp to `ai_diagnosis_usage`; raw issue descriptions are not persisted in that table.
- The usage table is inaccessible to `anon` and `authenticated`; only the server-side service role receives SELECT/INSERT privileges.
- The quota is five attempts per authenticated user per rolling hour. The Edge Function reserves a slot through `public.reserve_ai_diagnosis_slot`; a transaction-scoped advisory lock serializes reservations per user. Only the Supabase `service_role` can execute the reservation RPC.
- Gemini's free tier has usage limits and may process submitted content under Google's free-tier data terms. Do not send sensitive personal information.

## Deployment

Run from the repository root after linking the correct NexHelp Supabase project:

```bash
supabase secrets set GEMINI_API_KEY=your_google_ai_studio_key --yes
supabase secrets set GEMINI_MODEL=gemini-3.8-flash --yes
supabase db push --yes --remote
supabase functions deploy diagnose-service --yes
```

The project must have all ten migrations applied. Never commit the API key or service-role key.

## Model configuration

The default model is `gemini-3.8-flash`. Set `GEMINI_MODEL` to another supported Gemini API model if required. The Edge Function uses the Gemini `generateContent` REST endpoint with JSON response schema enforcement.


## Quota concurrency

The Edge Function reserves each assessment through `public.reserve_ai_diagnosis_slot`. The database serializes reservations per user with a transaction-scoped advisory lock, counts the rolling one-hour window, and inserts usage metadata only when capacity remains. Browser and mobile roles cannot reserve or forge quota records.
