# Calebsons Remix + Supabase — Realtime Collaboration App

## Overview
A real-time collaboration app using Remix loaders/actions and Supabase realtime features.

## Tech Stack
- Remix
- Supabase
- PostgreSQL
- TypeScript

## Features
- Realtime presence
- Shared editing
- File uploads
- Offline-first sync
- Auth + RBAC

## Architecture
```mermaid
flowchart TD
    C[Browser - Remix] --> LOADERS[Remix Loaders / Actions]
    LOADERS --> SUPA[Supabase Backend]
    SUPA --> DB[Postgres]
    SUPA --> RT[Realtime Channels]
    SUPA --> STORAGE[File Storage]
    C <-- RT --> SUPA

```

## Setup
    npm install
    npm run dev

## Deployment
- Fly.io
- Supabase hosting

## Roadmap
- Add voice rooms
- Add document versioning
