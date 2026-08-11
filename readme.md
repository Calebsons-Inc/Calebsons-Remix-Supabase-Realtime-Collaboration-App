# Calebsons Remix — Realtime Collaboration App

## Overview
Remix + local Supabase collaboration app. Week 1 complete: Supabase Auth, spaces, document save, and editor-only writes.

## Tech Stack
- Remix + Vite
- TypeScript
- Local Supabase (Docker): Auth, Postgres, RLS
- Username-only sign-in (maps to Supabase email auth under the hood)

## Week 1 features
- Sign up / sign in / sign out via Supabase Auth
- Protected `/spaces` layout
- Create + list spaces
- Space detail with document body
- Save document to Supabase (Owners/Editors only; Viewers read-only)
- Live document sync + presence via Supabase Realtime
- SQL migrations: `spaces`, `memberships`, `profiles`, RLS

## Prerequisites
- Node.js 20+
- Docker Desktop running
- npm

## Setup

```bash
npm install
cp .env.example .env          # first time only
npm run supabase:start        # Docker must be running
npm run db:reset              # apply migrations (first time / when schema changes)
npm run dev
```

Open:
- App: [http://localhost:5173](http://localhost:5173)
- Supabase Studio: [http://localhost:54323](http://localhost:54323)
- API: [http://127.0.0.1:54321](http://127.0.0.1:54321)

## Useful commands

```bash
npm run supabase:status
npm run db:migrate          # apply new local migrations (keeps data)
npm run db:reset            # wipe local DB and re-apply all migrations
npm run supabase:stop
```

Do **not** use `npx supabase db push` unless you have linked a cloud project (`supabase link`). Local Docker uses `db:migrate` / `db:reset`.

## Try Week 1
1. Open the app and create an account (username + display name).
2. Create a space on `/spaces`.
3. Open the space and edit the document — it saves to Supabase.
4. In another browser, create a second user.
5. As Owner, invite that username from the space sidebar. They can refresh `/spaces` and open it.

## Notes
- Auth is username-only in the UI; credentials are stored in local Supabase Auth.
- First creator of a space becomes **Owner** (via DB trigger).
- Realtime presence/sync is Week 2.
- Local demo keys in `.env.example` are for local use only.
