# Calebsons Remix — Realtime Collaboration App

## Overview
A real-time collaboration room with accounts, presence, shared editing, and file uploads.
Open two browsers, sign in as different users, and edit together.

## Tech Stack
- Remix + Vite
- TypeScript
- Cookie sessions (local auth)
- Server-sent events for realtime sync
- File uploads to `public/uploads`

## Features
- Sign up / sign in / sign out
- Live presence across browsers
- Shared document sync (last-write-wins)
- File uploads visible to everyone in the room
- Activity feed
- Offline queue for document edits (real browser offline)

## Setup
```bash
npm install
npm run dev
```

Open [http://localhost:5173](http://localhost:5173).

## Test realtime collaboration
1. In browser A: create an account (e.g. username `maya`).
2. In browser B (or a private window): create a different account (e.g. `jordan`).
3. Both land in `/room` — edit the shared document in either window; the other updates live.
4. Upload a file in one window — it appears in both.

## Notes
- Local users and room state persist under `data/`.
- First account created becomes **Owner**; later accounts are **Editors**.
- Supabase can replace the local auth/store later; the UI and room flow stay the same.
