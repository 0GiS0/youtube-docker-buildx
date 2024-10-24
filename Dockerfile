FROM nginx

WORKDIR  /usr/share/nginx/html

# Copy the static files to the nginx directory
COPY halloween-content/. .

# Expose the port
EXPOSE 80

# Start the server
CMD ["nginx", "-g", "daemon off;"]