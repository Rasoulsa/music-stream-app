# ─── Stage 1: Build ───────────────────────────────────
FROM node:22-alpine AS build

WORKDIR /app

# Install deps first (layer caching — only re-runs if lockfile changes).
COPY package*.json ./
RUN npm ci

# Copy source and build.
COPY . .

# Vite bakes env vars at build time → pass via build arg.
ARG VITE_API_BASE_URL=http://127.0.0.1:8000/api/v1
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

RUN npm run build

# ─── Stage 2: Serve ───────────────────────────────────
FROM nginx:alpine AS production

# Replace default nginx config with our SPA config.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built static files from stage 1.
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

# nginx runs in foreground by default in this image.
CMD ["nginx", "-g", "daemon off;"]
