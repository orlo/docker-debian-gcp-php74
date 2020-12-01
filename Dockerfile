# docker build --build-arg http_proxy=http://192.168.0.66:3128 --build-arg https_proxy=http://192.168.0.66:3128 .
FROM debian:buster

ENV LC_ALL C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive
ARG http_proxy=""
ARG https_proxy=""

# http://pecl.php.net/package/grpc
ENV GRPC_VERSION 1.33.1

# http://pecl.php.net/package/protobuf
ENV PROTOBUF_VERSION 3.13.0.1
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
        php7.4 php7.4-cli php7.4-curl php7.4-json php7.4-xml php7.4-mysql php7.4-mbstring php7.4-bcmath php7.4-zip php7.4-mysql php7.4-dev php7.4-sqlite3 php7.4-opcache php7.4-xml php7.4-xsl php7.4-intl php7.4-xdebug \
        zip unzip \
        zlib1g-dev libprotobuf-dev && \
    rm -f /etc/php/*/*/conf.d/*xdebug* && \
    mkdir /tmp/build && cd /tmp/build && curl -so pecl.tgz https://pecl.php.net/get/grpc-${GRPC_VERSION}.tgz && tar --no-same-owner -zxf pecl.tgz && cd grpc-${GRPC_VERSION} && \
    phpize . && autoreconf --force --install && \
    ./configure && \
    eatmydata -- make && \
    make install && cd /tmp/build && rm pecl.tgz && \
    cd /tmp/build && curl -so pecl.tgz https://pecl.php.net/get/protobuf-${PROTOBUF_VERSION}.tgz && tar --no-same-owner -zxf pecl.tgz && cd protobuf-${PROTOBUF_VERSION} && \
    phpize . && autoreconf --force --install && \
    ./configure && \
    eatmydata -- make && make install && \
    cd /tmp && rm -Rf /tmp/build && \
    apt-get remove -y --purge php7.4-dev zlib1g-dev libprotobuf-dev && \
    eatmydata -- apt-get -y autoremove && \
    apt-get clean && \
    rm -Rf /var/lib/apt/lists/* && \
    a2enmod headers rewrite deflate php7.4

COPY ./provisioning/php.ini /etc/php/7.4/apache2/conf.d/local.ini
COPY ./provisioning/php.ini /etc/php/7.4/cli/conf.d/local.ini

RUN echo GMT > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata \
    && mkdir -p "/var/log/apache2" \
    && ln -sfT /dev/stderr "/var/log/apache2/error.log" \
    && ln -sfT /dev/stdout "/var/log/apache2/access.log" \
    && ln -sfT /dev/stdout "/var/log/apache2/other_vhosts_access.log"

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
EXPOSE 80
