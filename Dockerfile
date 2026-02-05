# 1. Use Node Image
FROM node:18-alpine

# 2. Set working directory
WORKDIR /app

# 3. Copy package.json from the BACKEND folder
#    (Source: backend/package.json -> Dest: ./package.json)
COPY backend/package.json backend/package-lock.json ./

# 4. Install dependencies (Using NPM, not APT)
RUN npm install --production

# 5. Copy the backend code
COPY backend ./backend

# 6. Copy the public assets
COPY public ./public

# 7. Expose Port
EXPOSE 3000

# 8. Start the app
CMD ["node", "backend/app.js"]