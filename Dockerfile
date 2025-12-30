# Multi-stage Dockerfile for Strapi production deployment
# Using npm and Node 22 (required by package.json engines)

# ===================================
# Stage 1: Base Alpine image
# ===================================
FROM node:22-alpine AS base
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat

# ===================================
# Stage 2: Install dependencies (Dev + Prod for building)
# ===================================
FROM base AS deps
WORKDIR /app
COPY package.json package-lock.json ./
# Install ALL dependencies (including devDependencies like typescript) for the build step
RUN npm ci

# ===================================
# Stage 3: Build application
# ===================================
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NODE_ENV=production
# Build the application (transpiles TS to JS in /dist)
RUN npm run build

# ===================================
# Stage 4: Install Production dependencies only
# ===================================
FROM base AS prod-deps
WORKDIR /app
COPY package.json package-lock.json ./
# Install only production dependencies to keep the image small
RUN npm ci --omit=dev && npm cache clean --force

# ===================================
# Stage 5: Production runtime
# ===================================
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# Create non-root user for security
RUN addgroup --system --gid 1001 strapi && \
    adduser --system --uid 1001 strapi

# Copy production dependencies
COPY --from=prod-deps /app/node_modules ./node_modules
# Copy build artifacts
COPY --from=builder /app/dist ./dist
# Copy static assets and config
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./
COPY --from=builder /app/database ./database
COPY --from=builder /app/config ./config
# Note: src is usually not needed in prod if fully built to dist, keeps image smaller
# But some plugins might rely on it. For standard Strapi 5, dist/ and node_modules/ should suffice.

# Set permissions
RUN chown -R strapi:strapi /app

USER strapi

EXPOSE 1337

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD node -e "require('http').get('http://localhost:1337/_health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["npm", "start"]
