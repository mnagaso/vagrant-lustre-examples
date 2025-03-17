FROM node:23-alpine
WORKDIR /app
# Initialize a simple Next.js application using the app directory (Next.js 13+)
RUN npm init -y && npm install next react react-dom
# Create a minimal Next.js page in the app directory
RUN mkdir app && \
    echo "export default function Page() { return <div>Hello, Next.js App Directory!</div>; }" > app/page.jsx
# Expose application port
EXPOSE 3000
# Start the Next.js development server
CMD ["npx", "next", "dev"]
