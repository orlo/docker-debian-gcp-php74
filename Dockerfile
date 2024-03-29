# docker build --build-arg http_proxy=http://192.168.0.66:3128 --build-arg https_proxy=http://192.168.0.66:3128 .
FROM debian:buster-slim as base

ARG COMPOSER_SHA256="1ffd0be3f27e237b1ae47f9e8f29f96ac7f50a0bd9eef4f88cdbe94dd04bfff0"

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
COPY ./provisioning/debsury.gpg /usr/share/keyrings/deb.sury.org-php.gpg

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
    rm /etc/apache2/conf-enabled/other-vhosts-access-log.conf /etc/apache2/conf-enabled/serve-cgi-bin.conf && \
    a2enmod headers rewrite deflate php7.4

COPY ./provisioning/php.ini /etc/php/7.4/apache2/conf.d/local.ini
COPY ./provisioning/php.ini /etc/php/7.4/cli/conf.d/local.ini

RUN curl -so /usr/local/bin/composer https://getcomposer.org/download/2.7.1/composer.phar && chmod 755 /usr/local/bin/composer

# 0844c3dd85bbfa039d33fbda58ae65a38a9f615fcba76948aed75bf94d7606ca  /usr/local/bin/composer
RUN echo "${COMPOSER_SHA256}  /usr/local/bin/composer" | sha256sum --check

RUN echo GMT > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata \
    && mkdir -p "/var/log/apache2" \
    && ln -sfT /dev/stderr "/var/log/apache2/error.log" \
    && ln -sfT /dev/stdout "/var/log/apache2/access.log" 

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
EXPOSE 80
