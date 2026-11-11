import { redactObviousIdentifiers } from "./redaction.ts";

Deno.test("redacts Indian mobile numbers and email addresses", () => {
  const input = "Call +91 9876543210 or email customer@example.com about the leaking tap.";
  const output = redactObviousIdentifiers(input);
  if (output.includes("9876543210") || output.includes("customer@example.com")) {
    throw new Error("A phone number or email address was not redacted.");
  }
  if (!output.includes("[phone redacted]") || !output.includes("[email redacted]")) {
    throw new Error("Expected redaction markers were not added.");
  }
});

Deno.test("redacts Aadhaar-like and PAN-like identifiers", () => {
  const input = "ID 1234 5678 9012 and PAN ABCDE1234F";
  const output = redactObviousIdentifiers(input);
  if (output.includes("1234 5678 9012") || output.includes("ABCDE1234F")) {
    throw new Error("A government identifier was not redacted.");
  }
  if ((output.match(/\[government ID redacted\]/g) || []).length !== 2) {
    throw new Error("Expected two government-ID redaction markers.");
  }
});

Deno.test("preserves ordinary repair details and the pilot pincode", () => {
  const input = "Kitchen sink pipe is leaking near the tap. Service pincode 560102.";
  const output = redactObviousIdentifiers(input);
  if (output !== input) {
    throw new Error("Ordinary service details or pincode were unexpectedly changed.");
  }
});
