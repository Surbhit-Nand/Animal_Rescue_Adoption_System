# syntax=docker/dockerfile:1
#
# ARA: one container serving the built React SPA and the Express API from the
# same origin. The git repo root is this directory, while the app itself lives
# in ARA_System/, so every path below is prefixed with it - Fly builds from the
# repo root.
#
# Frontend build-time config (Vite inlines VITE_* at build time, not runtime):
#   VITE_CLERK_PUBLISHABLE_KEY - public key, passed as a build arg from fly.toml
# VITE_API_URL is deliberately not set: in a production build the frontend calls
# its own origin (see src/services/apiClient.ts).

FROM node:24-bookworm-slim AS build
WORKDIR /app

# Install with the lockfile first so dependency layers cache across deploys.
COPY ARA_System/package.json ARA_System/package-lock.json ./
RUN npm ci

COPY ARA_System/ ./

ARG VITE_CLERK_PUBLISHABLE_KEY
ENV VITE_CLERK_PUBLISHABLE_KEY=$VITE_CLERK_PUBLISHABLE_KEY
# Fail here rather than shipping a bundle that cannot start Clerk.
RUN if [ -z "$VITE_CLERK_PUBLISHABLE_KEY" ]; then \
      echo "Missing build arg VITE_CLERK_PUBLISHABLE_KEY - set it in fly.toml [build.args]." >&2; \
      exit 1; \
    fi

# `npm run build` typechecks + builds the SPA into dist/, then tsc compiles the
# Express server (NodeNext ESM) into server/dist/.
RUN npm run build && npm run server:build


FROM node:24-bookworm-slim AS runtime
ENV NODE_ENV=production
WORKDIR /app

COPY ARA_System/package.json ARA_System/package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Only build output is copied - no TypeScript sources, no dev toolchain.
COPY --from=build /app/dist ./dist
COPY --from=build /app/server/dist ./server/dist

# Matches API_PORT (fly.toml [env]) and [http_service].internal_port.
EXPOSE 8080
USER node

CMD ["node", "server/dist/server.js"]
