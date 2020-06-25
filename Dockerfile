FROM ruby:2.6.5
LABEL maintainer="pierre.courbin@gmail.com"

ARG decidim_version=0.21.0

ENV DECIDIM_PATH /app
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update \
  && apt-get install -y git imagemagick wget nano \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
  && apt-get install -y nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g npm@6.14.3

RUN gem install decidim:$decidim_version
WORKDIR /
RUN decidim $DECIDIM_PATH

WORKDIR $DECIDIM_PATH

ADD       ./decidim.sh ${DECIDIM_PATH}/
RUN       chmod +x ${DECIDIM_PATH}/decidim.sh
CMD       ["./decidim.sh"]
