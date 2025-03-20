# Stage 1: Build the application
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json ./
COPY package-lock.json ./
RUN npm install
COPY . .
ENV MONGODB_URI=mongodb://db:27017
RUN npm run build

# Stage 2: Run the application
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
# Copy necessary files from builder stage
COPY --from=builder /app/package.json ./
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/.next ./.next
RUN npm install --only=production
EXPOSE 3000
CMD ["npm", "start"]
