# syntax=docker/dockerfile:1
# agent-kit: PHP app on FrankenPHP (Caddy + PHP in one process). Non-root, prod deps only.
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --no-scripts --no-autoloader
COPY . .
RUN composer dump-autoload --no-dev --optimize --classmap-authoritative

FROM dunglas/frankenphp:1-php8.3 AS runtime
RUN install-php-extensions pdo_pgsql pdo_mysql intl opcache zip \
 && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
ENV SERVER_NAME=:8080
WORKDIR /app
COPY --from=vendor /app /app
RUN useradd --uid 10001 --no-create-home app \
 && chown -R app:app /app /data/caddy /config/caddy
USER app
EXPOSE 8080
