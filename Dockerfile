# Stage 1: Build frontend assets
FROM node:20 as frontend
WORKDIR /app
COPY package*.json vite.config.js ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Serve the application
FROM php:8.3-cli

# Install system dependencies (minimized)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libpq-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy existing application directory contents
COPY . /var/www

# Copy built frontend assets from Stage 1 ensures we don't need npm in production
COPY --from=frontend /app/public/build /var/www/public/build

# Install dependencies (only production)
RUN composer install --no-dev --optimize-autoloader

# Fix permissions
RUN chown -R www-data:www-data /var/www

# Expose port (Render sets PORT env)
EXPOSE 8000

# Start command
CMD sh -c "php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=${PORT:-8000}"
