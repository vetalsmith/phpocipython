FROM php:fpm

ENV LD_LIBRARY_PATH="/usr/local/lib;/usr/local/instantclient"
ENV NLS_LANG="AMERICAN_AMERICA.AL32UTF8"

#PHP 8 https://pecl.php.net/package/oci8
ARG OCI8="oci8-3.2.1"

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y \
        make \
        zip \
        libaio1 \
        python3 \
        python3-pandas \        
        ca-certificates && \
    apt-get clean -y && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/*

#https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html
#Basic: All files required to run OCI, OCCI, and JDBC-OCI applications (60,704,657 bytes) (cksum - 41267059)
#SDK: Additional header files and an example makefile for developing Oracle applications with Instant Client (643,089 bytes) (cksum - 3927039586)

COPY instantclient-basic-linux.x64-11.2.0.4.0.zip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip
COPY instantclient-sdk-linux.x64-11.2.0.4.0.zip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip
COPY $OCI8.tgz /tmp/$OCI8.tgz

RUN unzip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip -d /usr/local/ && \
    unzip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip -d /usr/local/ && \
    apt-get remove zip -y && \
    cd /tmp && \
    tar zxvf $OCI8.tgz
    
RUN ln -s /usr/local/instantclient_11_2 /usr/local/instantclient && \
    ln -s /usr/local/instantclient/libclntsh.so.11.1 /usr/local/instantclient/libclntsh.so && \
    echo /usr/local/instantclient > /etc/ld.so.conf.d/php_oci8.conf && \
    ldconfig && \
    cd /tmp/$OCI8/ && \
    phpize && \
    ./configure --with-oci8=instantclient,/usr/local/instantclient && \
    make && \
    make install && \
    docker-php-ext-enable oci8 && \
    apt-get remove make -y
