FROM php:8.3-cli

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libpq-dev \
    nodejs \
    npm

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy existing application directory contents
COPY . /var/www

# Install dependencies
RUN composer install --no-dev --optimize-autoloader
RUN npm install && npm run build

# Fix permissions
RUN chown -R www-data:www-data /var/www

# Expose port (Render sets PORT env)
EXPOSE 8000

# Start command
# Uses sh -c to ensure environment variables like PORT are expanded
CMD sh -c "php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=${PORT:-8000}"
