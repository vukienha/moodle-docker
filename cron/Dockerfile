FROM php:8.2-cli

RUN apt-get update && apt-get install -y --no-install-recommends cron && rm -rf /var/lib/apt/lists/*

COPY cron.sh /usr/local/bin/cron.sh
RUN chmod +x /usr/local/bin/cron.sh

CMD ["bash", "-c", "while true; do /usr/local/bin/cron.sh; sleep 60; done"]
