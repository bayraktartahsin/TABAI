# Hugging Face Spaces (Docker) - Next.js standalone

FROM node:20-bookworm-slim AS builder
WORKDIR /app
ENV DATABASE_URL="file:./prisma/dev.db"
ENV TAI_ENCRYPTION_KEY="hf-build-encryption-key"
ENV TAI_BOOTSTRAP_ADMIN_EMAIL="admin@tai.local"
ENV TAI_BOOTSTRAP_ADMIN_USERNAME="admin"
ENV TAI_BOOTSTRAP_ADMIN_PASSWORD="ChangeMe123!"
ENV TAI_BOOTSTRAP_USER_EMAIL="user@tai.local"
ENV TAI_BOOTSTRAP_USER_USERNAME="user"
ENV TAI_BOOTSTRAP_USER_PASSWORD="ChangeMe123!"
ENV TAI_BOOTSTRAP_OPENWEBUI_URL="https://ai.tahsinbayraktar.com"
ENV TAI_BOOTSTRAP_OPENWEBUI_MODEL_ID="gpt-4o-mini"
ENV TAI_BOOTSTRAP_OPENWEBUI_MODEL_NAME="GPT-4o mini"

COPY package.json package-lock.json* ./
RUN npm ci || npm install

COPY . .
RUN npx prisma generate
RUN npx prisma db push --skip-generate
RUN node prisma/seed.mjs
RUN npm run build

FROM node:20-bookworm-slim AS runner
ENV NODE_ENV=production
ENV PORT=7860
ENV HOSTNAME=0.0.0.0
ENV DATABASE_URL="file:./prisma/dev.db"
ENV TAI_ENCRYPTION_KEY="hf-runtime-encryption-key"
WORKDIR /app

# Next.js standalone output contains its own node_modules subset.
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
COPY --from=builder /app/prisma ./prisma
COPY startup.mjs ./startup.mjs

EXPOSE 7860
CMD ["node", "startup.mjs"]
