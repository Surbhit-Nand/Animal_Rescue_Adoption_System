// Single shared copy of the frontend API plumbing: base URL, the
// dev-server-not-running guard, and Clerk bearer headers. Every service
// module and data-fetching page imports from here instead of re-implementing
// it, so the API origin and the offline error stay consistent app-wide.
// VITE_API_URL wins when set (staging, separate API host). Otherwise a
// production build talks to its own origin - the deployed container serves the
// built SPA and the API from one host - while local dev keeps hitting the
// separate `npm run server:dev` process. `import.meta.env` is undefined under
// plain Node (tsx tests), hence the optional chaining.
export const apiBaseUrl =
  import.meta.env?.VITE_API_URL ??
  (import.meta.env?.PROD ? "" : "http://localhost:8787");

export async function readApiResponse<T>(response: Response): Promise<T> {
  const contentType = response.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) {
    throw new Error("The SPCA API is not running. Start it with `npm run server:dev`.");
  }
  return (await response.json()) as T;
}

export function authHeaders(token?: string, extra?: Record<string, string>) {
  return token
    ? { Authorization: `Bearer ${token}`, ...extra }
    : { ...extra };
}
