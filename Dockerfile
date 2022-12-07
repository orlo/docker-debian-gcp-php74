# docker build --build-arg http_proxy=http://192.168.0.66:3128 --build-arg https_proxy=http://192.168.0.66:3128 .
FROM debian:buster-slim as base

ENV LC_ALL C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive
ARG http_proxy=""
ARG https_proxy=""

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/force-unsafe-io && \
    apt-get -q update && \
    apt-get install -y eatmydata  && \
    eatmydata -- apt-get install -y apt-transport-https ca-certificates && \
    apt-get clean && rm -Rf /var/lib/apt/lists/*

COPY ./provisioning/sources.list /etc/apt/sources.list
COPY ./provisioning/debsury.gpg /etc/apt/trusted.gpg.d/debsury.gpg

RUN apt-get -qq update && \
    eatmydata -- apt-get -qy install \
        apache2 libapache2-mod-php7.4 \
        curl \
        git-core \
        netcat \
        jq \
        php7.4 php7.4-cli php7.4-curl php7.4-json php7.4-xml php7.4-mysql php7.4-mbstring php7.4-bcmath php7.4-zip php7.4-mysql php7.4-sqlite3 php7.4-opcache php7.4-xml php7.4-xsl php7.4-intl php7.4-apcu php7.4-grpc php7.4-protobuf zip unzip && \
    apt-get clean && \
    rm -Rf /var/lib/apt/lists/* && \
    update-alternatives --set php /usr/bin/php7.4 && \
    a2enmod headers rewrite deflate php7.4

COPY ./provisioning/php.ini /etc/php/7.4/apache2/conf.d/local.ini
COPY ./provisioning/php.ini /etc/php/7.4/cli/conf.d/local.ini

RUN curl -so /usr/local/bin/composer https://getcomposer.org/download/2.4.4/composer.phar && chmod 755 /usr/local/bin/composer

RUN echo GMT > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata \
    && mkdir -p "/var/log/apache2" \
    && ln -sfT /dev/stderr "/var/log/apache2/error.log" \
    && ln -sfT /dev/stdout "/var/log/apache2/access.log" \
    && ln -sfT /dev/stdout "/var/log/apache2/other_vhosts_access.log"

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
EXPOSE 80
