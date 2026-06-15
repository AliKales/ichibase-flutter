// search.ts — Typesense full-text search proxy Edge Function (Deno, PRO).
//
// Typesense's admin/search key must stay server-side. This function holds the
// key, runs the query against your collection, and returns just the hits.
//
// The client calls it via:
//   ichi.functions.invoke('search', body: { q: 'shoes', collection: 'products' })
//
// Env (injected by the dashboard):
//   TYPESENSE_URL         e.g. https://search.myapp.ichibase.net
//   TYPESENSE_API_KEY     a search-only or admin key (NEVER ship to a client)

const TS_URL = Deno.env.get("TYPESENSE_URL")!;
const TS_KEY = Deno.env.get("TYPESENSE_API_KEY")!;

interface SearchRequest {
  q?: string;
  collection?: string;
  query_by?: string;
  per_page?: number;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return json({ code: "method_not_allowed", detail: "POST only" }, 405);
  }

  let body: SearchRequest;
  try {
    body = (await req.json()) as SearchRequest;
  } catch {
    return json({ code: "bad_request", detail: "invalid JSON body" }, 400);
  }

  const q = body.q ?? "";
  const collection = body.collection ?? "products";
  const queryBy = body.query_by ?? "name,description";
  const perPage = body.per_page ?? 10;

  if (!q) return json({ code: "bad_request", detail: "q is required" }, 400);

  const params = new URLSearchParams({
    q,
    query_by: queryBy,
    per_page: String(perPage),
  });

  const res = await fetch(
    `${TS_URL}/collections/${collection}/documents/search?${params}`,
    { headers: { "x-typesense-api-key": TS_KEY } },
  );

  if (!res.ok) {
    return json(
      { code: "search_failed", detail: `typesense HTTP ${res.status}` },
      res.status,
    );
  }

  const data = await res.json();
  // Return a slimmed-down shape: the documents and the total found.
  const hits = (data.hits ?? []).map((h: { document: unknown }) => h.document);
  return json({ found: data.found ?? hits.length, hits });
});
