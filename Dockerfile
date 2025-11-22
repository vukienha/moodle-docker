FROM php:8.2-fpm

ARG DEBIAN_FRONTEND=noninteractive
ARG MOODLE_SRC_DIR=/usr/src/moodle
ARG MOODLE_WWW_DIR=/var/www/html

# Install PHP extension installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    /usr/local/bin/install-php-extensions
RUN chmod +x /usr/local/bin/install-php-extensions

# System dependencies for Moodle + DB connectors
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git unzip locales tzdata \
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev libicu-dev \
    libxml2-dev libxslt1-dev libzip-dev \
    libmariadb-dev libpq-dev netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# Install PHP extensions needed for Moodle
RUN install-php-extensions \
    intl mysqli pdo_mysql \
    soap xsl exif sockets \
    gd ldap zip \
    opcache \
    redis memcached apcu igbinary uuid

# Enable APCu for CLI
RUN echo 'apc.enable_cli=1' > /usr/local/etc/php/conf.d/99-apcu.ini

# Prepare dirs 
RUN mkdir -p ${MOODLE_SRC_DIR} ${MOODLE_WWW_DIR}
RUN chown -R www-data:www-data ${MOODLE_WWW_DIR}

# RUN	echo "Download and extract moodle code"; \
# 	curl -o moodle.tgz -fSL "https://download.moodle.org/download.php/stable405/moodle-latest-405.tgz"; \
# 	tar -xf moodle.tgz -C ${MOODLE_SRC_DIR} --strip 1; \
# 	rm moodle.tgz

# Copy and extract moodle code
COPY src/moodle-latest-405.tgz moodle.tgz
RUN tar -xf moodle.tgz -C ${MOODLE_SRC_DIR} --strip 1; \
    rm moodle.tgz

# Copy Entry script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME ["/var/www/moodledata"]

WORKDIR /var/www/html
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["php-fpm"]
