# Build stage
FROM node:20-alpine AS builder

# Add labels
LABEL org.opencontainers.image.title="Hugging Face API Gateway"
LABEL org.opencontainers.image.description="A Node.js API Gateway for Hugging Face models"
LABEL org.opencontainers.image.vendor="Hugging Face"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/your-org/huggingface"
LABEL org.opencontainers.image.version="1.0.0"

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code and necessary files
COPY . .

# Build TypeScript
RUN npm run build

# Production stage
FROM node:20-alpine

# Add labels
LABEL org.opencontainers.image.title="Hugging Face API Gateway"
LABEL org.opencontainers.image.description="A Node.js API Gateway for Hugging Face models"
LABEL org.opencontainers.image.vendor="Hugging Face"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/your-org/huggingface"
LABEL org.opencontainers.image.version="1.0.0"

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache curl

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy built files from builder stage
COPY --from=builder /app/dist ./dist

# Create logs directory
RUN mkdir -p /app/logs

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${PORT}/models/health || exit 1

# Start the application
CMD ["node", "dist/src/index.js"] 