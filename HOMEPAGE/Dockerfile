# Stage 1: Build the Vue.js application
FROM node:24 as build-stage

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy the rest of the application source code
COPY . .

# Build the application for production
RUN npm run build

# The 'dist' directory is now created and will be available for nginx to serve
# This is a build-only container - the dist folder will be mounted to nginx
