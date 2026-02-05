# 1. Use a lightweight, production-ready base image
FROM node:18-alpine

# 2. Set the working directory inside the container
WORKDIR /app

# 3. Copy package definitions first
# This allows Docker to cache dependencies if package.json hasn't changed
COPY package*.json ./

# 4. Install dependencies
RUN npm install --production

# 5. Copy the rest of the application code
COPY . .

# 6. Expose the application port (Standard for Node apps is often 3000 or 8080)
EXPOSE 3000

# 7. Define the command to run your app
# Adjust "backend/server.js" if your entry file has a different name
CMD ["node", "backend/server.js"]