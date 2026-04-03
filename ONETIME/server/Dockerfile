FROM node:20-alpine AS frontend-build

WORKDIR /build

# Copy package files for Vue frontend
COPY package.json package-lock.json* ./
RUN npm install --ignore-engines

# Copy Vue source and build (skip type-check — belongs in CI, not prod builds)
COPY . .
RUN npm run build-only

# ── Production image (lightweight — no docker/git/certbot needed) ──
FROM node:20-alpine

WORKDIR /app

# Copy server files
COPY server/package.json server/server.js ./server/

# Copy built Vue3 frontend from build stage
COPY --from=frontend-build /build/dist ./dist/

# Install server dependencies
WORKDIR /app/server
RUN npm install --production

EXPOSE 9090

CMD ["node", "server.js"]
