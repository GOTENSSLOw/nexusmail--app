# NexusMail Frontend

React + Vite email client for the NexusMail mail server stack.

## Overview

NexusMail Frontend is a single-page application that provides a modern web interface for reading and managing email. It communicates with the NexusMail backend API and handles IMAP operations through the Django server.

## API Connection

The frontend connects to the backend API at `http://localhost:8000`. This is configured via the `VITE_API_URL` environment variable (optional — defaults to `http://localhost:8000`).

## Development

```bash
cd frontend
npm install
npm run dev
```

The dev server runs on `http://localhost:5173` by default.

## Build

```bash
npm run build
```

Output goes to `dist/`. Serve with any static file server:

```bash
npx serve dist
```

## Docker Integration

In the Docker Compose setup, the frontend runs in a container and is accessible at `http://localhost:5173`. The container uses Vite in preview mode to serve the production build.

For local development while the API runs in Docker:

```bash
# In frontend/.env (optional)
VITE_API_URL=http://localhost:8000
```

## Tech Stack

- **React 18** — UI framework
- **Vite** — Build tool and dev server
- **TypeScript** — Type safety