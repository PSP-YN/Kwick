export function logAdminError(event: string, error?: unknown): void {
  const safeEvent = event.toLowerCase().replace(/[^a-z0-9_.-]+/g, '_').slice(0, 80);
  if (process.env.NODE_ENV !== 'production' && error !== undefined) {
    console.error('[Kwick]', safeEvent, error);
    return;
  }
  console.error('[Kwick]', safeEvent);
}
