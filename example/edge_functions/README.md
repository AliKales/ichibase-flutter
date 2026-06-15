# Edge Functions for the example app

These Deno/TypeScript functions run **server-side** with secrets the client must
never see (the project **service key**, the **Typesense** admin key). The Flutter
app calls them with `ichi.functions.invoke('files' | 'search', ...)`.

| File        | Function name | Used by                | Holds (server-side)        |
| ----------- | ------------- | ---------------------- | -------------------------- |
| `files.ts`  | `files`       | Storage screen         | `ICHIBASE_SERVICE_KEY`     |
| `search.ts` | `search`      | Pro features (Typesense) | `TYPESENSE_API_KEY`      |

## Deploy

1. In the dashboard, go to **Functions → New**.
2. Create a function named exactly `files` and paste in `files.ts`. Repeat for
   `search` with `search.ts`.
3. The platform injects env vars automatically:
   - `ICHIBASE_PROJECT_URL` — your `https://<slug>.ichibase.net`
   - `ICHIBASE_SERVICE_KEY` — the `ich_admin_` service key (for `files`)
   - For `search`, add `TYPESENSE_URL` and `TYPESENSE_API_KEY` (Pro).
4. Save/deploy. The client can now invoke them.

## Why a gateway?

The client SDK is **anon-only** — it refuses `ich_admin_` keys and ships no
storage module. Anything that needs the service key (signing read/upload URLs,
deleting objects) or another admin secret (Typesense) lives in an Edge Function:

```text
Flutter app ──invoke('files', { op:'put', ... })──▶  files.ts  ──Bearer ich_admin_──▶  /storage/get-put-url
   (anon key + user token)                          (service key, server-side)
```

The function **authenticates the caller** (the SDK attaches the signed-in
user's token as `Authorization: Bearer`), **authorizes** the requested path,
then forwards to the control plane with the service key and returns only what
the client needs (a `{ url }`).
