FROM debian:stretch
MAINTAINER Yuki Furuta

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q -qq && \
apt-get install -q -qq -y gnupg apt-utils wget && \
apt-get clean -q -qq

RUN echo "deb http://repo.aptly.info/ squeeze main" > /etc/apt/sources.list.d/aptly.list && \
wget -qO - https://www.aptly.info/pubkey.txt | apt-key add - && \
apt-get update -q -qq && \
apt-get install aptly ca-certificates nginx supervisor -y && \
apt-get clean

ADD aptly.conf /etc/aptly.conf

VOLUME ["/aptly"]
