FROM node:23-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
RUN npm install @tailwindcss/oxide-linux-x64-musl
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
