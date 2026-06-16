# ichibase (Dart / Flutter)

The official **client-side** SDK for [ichibase](https://ichibase.com) — Postgres,
MongoDB, Auth, Storage, and Realtime from a single client. Works in **Flutter**
(iOS, Android, web, desktop), Dart servers, and CLIs. **Anon key only.**

> Mirrors the TypeScript [`@ichibase/client`](https://github.com/AliKales/ichibase-client).
> Building a backend/admin tool with the **service** key? Use the server SDKs —
> this package refuses `ich_admin_` keys by design.

## Install

```yaml
# pubspec.yaml
dependencies:
  ichibase: ^0.1.0
```

```dart
import 'package:ichibase/ichibase.dart';

final ichi = Ichibase.createClient(
  'https://<project>.ichibase.net',
  'ich_pub_…', // publishable (anon) key — safe to ship in your app
);
```

## Database (PostgREST)

Awaiting a query runs it. Every call returns an `IchibaseResponse` with `data`
and `error` (check `res.ok`).

```dart
// Read with filters / ordering / pagination
final res = await ichi
    .from('posts')
    .select('id, title, author')
    .eq('published', true)
    .order('created_at', ascending: false)
    .limit(20);
print(res.data); // List of rows

// Insert / update / delete
await ichi.from('posts').insert({'title': 'Hello'});
await ichi.from('posts').update({'title': 'Edited'}).eq('id', 1);
await ichi.from('posts').delete().eq('id', 1);

// One row, or a total count
final one = await ichi.from('posts').select('*').eq('id', 1).single();
final counted = await ichi.from('posts').select('*').count(); // {rows, count}

// RPC (SQL function)
final total = await ichi.rpc('count_posts', args: {'author': userId});
```

## Auth + per-user access

After login, data calls use the user's access token, so your RLS policies and
realtime rules see them.

```dart
await ichi.auth.signup(email: email, password: password);
final login = await ichi.auth.login(email: email, password: password);

await ichi.from('posts').insert({'title': 'mine'}); // runs as the user

final user = await ichi.auth.getUser();
await ichi.auth.logout();

ichi.onAuthStateChange.listen((s) {
  // s.event == AuthEvent.signedIn | signedOut | tokenRefreshed
});
```

### Passwordless sign-in (OTP & magic link)

If the project enables it (custom SMTP required), users can sign in without a
password — a one-time code, a magic link, or both in one email. Additive to
email + password.

```dart
// 1. Send the sign-in email (always succeeds, even for unknown emails)
await ichi.auth.signInWithOtp(email: email);

// 2a. User typed the 6-digit code → signs them in (session is stored):
await ichi.auth.verifyOtp(email: email, code: code);

// 2b. …or exchange a magic-link token from your deep-link handler:
await ichi.auth.verifyMagicLink(token);
```

### 2-step verification (login)

If the project requires it (custom SMTP), `login` returns a **`LoginResult`**:
normally `result.session` is set, but when 2-step verification is on the
password step emails a factor and yields `result.twofaRequired == true`. Finish
with `verifyTwoFactor` (the code) or `verifyTwoFactorMagic` (the token).

```dart
final res = await ichi.auth.login(email: email, password: password);
if (res.data?.twofaRequired == true) {
  // a code / link was emailed (res.data!.twofaMethods) — prompt, then:
  await ichi.auth.verifyTwoFactor(email: email, code: code);
  // or: await ichi.auth.verifyTwoFactorMagic(token);
} else {
  final session = res.data?.session; // normal login
}
```

### Persisting the session

The session lives in memory by default. Plug in a `SessionStore` to keep users
logged in across restarts (back it with `shared_preferences` or
`flutter_secure_storage`), then hydrate once at startup:

```dart
final ichi = Ichibase.createClient(url, anonKey, store: MySecureStore());
await ichi.auth /* not needed */;
await ichi.loadSession();
```

## Mongo

```dart
await ichi.mongo.collection('orders').insertOne({'total': 42});
final docs = await ichi.mongo.collection('orders').find({'total': {'\$gt': 10}});
```

## Storage

Storage is **not** on the client. Read/upload tokens are minted server-side by
the project owner (an Edge Function using the service key) and handed to your
app — so private files stay the owner's responsibility. Public files are read
directly from `https://cdn.ichibase.net/<project>/public/<path>`. See the
[Storage docs](https://ichibase.com/docs/storage).

## Realtime

```dart
final sub = ichi.realtime.subscribe(
  kind: 'postgres',
  table: 'messages',
  events: ['INSERT'],
  onMessage: (msg) => print('${msg['event']} ${msg['record']}'),
);

// Broadcast + presence
final room = ichi.realtime.subscribe(
  kind: 'broadcast',
  channel: 'room:42',
  presence: true,
  onMessage: (msg) => print(msg),
);
room.send('chat', {'text': 'hi'});
room.track({'typing': true});

sub.unsubscribe();
```

## Security

The anon key is **publishable** — access is gated by your **Row-Level Security**
policies (Postgres) and **collection policies** (Mongo), not by hiding the key.
Enable RLS on everything you expose. Never put an `ich_admin_` (service) key in
an app. Full docs: <https://ichibase.com/docs>.

## License

MIT
