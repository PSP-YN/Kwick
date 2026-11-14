# Kwick — Provider Verification Procedure

Provider verification is an operational decision, not an automatic result of registration or document upload. A provider remains unavailable for customer dispatch until an authorized operator approves the profile.

## Minimum review sequence

1. **Reachability:** verify the provider's phone number and speak to the person who will perform the work.
2. **Identity:** inspect an accepted government-issued photo ID using the approved Kwick process. Avoid Aadhaar collection; do not collect Aadhaar biometrics, full Aadhaar numbers or Aadhaar e-KYC payloads. Confirm the accepted alternative-ID policy with legal counsel before launch.
3. **Trade competence:** inspect relevant training/certificates where available. If no certificate exists, record an in-person practical assessment and the reviewer's findings.
4. **References and work history:** speak to at least one appropriate reference or shop/employer contact where available. Record what was checked and when.
5. **Service area:** confirm the provider actually works in the neighbourhood and can travel within the advertised response window.
6. **Regulated work:** verify all licences, permits and qualifications applicable to the work. Do not dispatch electrical work requiring authorization to an unqualified provider.
7. **Safety and conduct:** brief the provider on customer consent, transparent quotes, scope changes, arrival communication, privacy, safety escalation and complaint handling.
8. **Pilot observation:** supervise initial jobs and review completion quality before expanding dispatch privileges.

## Evidence handling

- Provider documents are uploaded to a private storage bucket under the provider's user-specific folder.
- The app accepts JPG, PNG and PDF files up to 10 MB for the configured document types.
- Uploading a file only creates a pending review record. It does not approve a provider.
- Admin document links are temporary signed URLs; do not copy document URLs into public pages, chat messages or issue trackers.
- Record reviewer, date, document type, outcome, notes and any credential expiry. Restrict access to authorized operations staff.
- Define retention and deletion periods with legal counsel; remove documents when no longer needed, subject to lawful retention obligations.

## Approval rule

Approve only after the relevant checks are complete and the evidence is recorded. Rejected, suspended or incomplete providers must not receive assignments. Verification notes must be specific and auditable; a generic "checked" note is not sufficient.
