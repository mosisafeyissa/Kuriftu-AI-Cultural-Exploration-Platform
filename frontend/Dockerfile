# Stage 1: Build the Flutter web application
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy the source code
COPY . .

# Fetch dependencies and build for web
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve the built web app using Nginx
FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy our custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built Flutter output from the first stage
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
