# Multi-stage Dockerfile for Strapi production deployment
# Optimized for size and security

# ===================================
# Stage 1: Install dependencies
# ===================================
FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat python3 make g++
WORKDIR /app

# Copy package manager files
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# Enable corepack and install dependencies
RUN corepack enable && \
    corepack prepare yarn@4.9.4 --activate && \
    yarn install --immutable

# ===================================
# Stage 2: Build application
# ===================================
FROM node:20-alpine AS builder
WORKDIR /app

# Copy dependencies from previous stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set environment variables for build
ENV NODE_ENV=production

# Build Strapi admin panel
RUN corepack enable && \
    corepack prepare yarn@4.9.4 --activate && \
    yarn build

# ===================================
# Stage 3: Production runtime
# ===================================
FROM node:20-alpine AS runner
WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache libc6-compat

# Set production environment
ENV NODE_ENV=production

# Copy dependencies and build artifacts
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./
COPY --from=builder /app/database ./database
COPY --from=builder /app/config ./config
COPY --from=builder /app/src ./src

# Create non-root user for security
RUN addgroup --system --gid 1001 strapi && \
    adduser --system --uid 1001 strapi && \
    chown -R strapi:strapi /app

# Switch to non-root user
USER strapi

# Expose port 1337
EXPOSE 1337

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
  CMD node -e "require('http').get('http://localhost:1337/_health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start Strapi
CMD ["yarn", "start"]
