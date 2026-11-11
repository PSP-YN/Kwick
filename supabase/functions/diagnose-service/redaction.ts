export function redactObviousIdentifiers(value: string): string {
  return value
    .replace(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi, "[email redacted]")
    .replace(/(?:\+?91[\s-]?)?[6-9]\d{9}\b/g, "[phone redacted]")
    .replace(/\b\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/g, "[government ID redacted]")
    .replace(/\b[A-Z]{5}\d{4}[A-Z]\b/gi, "[government ID redacted]");
}
