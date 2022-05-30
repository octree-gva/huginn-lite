ARG NODE_VERSION=14.16.1
ARG BUNDLE_WITHOUT="test development"

FROM node:$NODE_VERSION-alpine AS node

FROM ruby:2.5.1-alpine as build
ENV BUNDLER_VERSION=2.0.2\
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_WITHOUT=$BUNDLE_WITHOUT \
    RAILS_ENV=production \
    RACK_ENV=production \
    HOME=/home/huginn\
    ROOT=/home/huginn/app\
    # Rails configuration
    RAILS_MAX_THREAD=25\
    RAILS_LOG_LEVEL="warn" \
    SECRET_KEY_BASE="insecure-secret" \
    RAILS_FORCE_SSL="enabled" \
    RAILS_SERVE_STATIC_FILES="false"\
    RAILS_PID_FILE="tmp/pids/server.pid" \
    RAILS_LOG_TO_STDOUT="true"\
    PORT=3000\
    DOCKER_EXPOSED_PORT=3000 \
    TIMEZONE="Europe/Zurich" \
    # Placeholders
    DATABASE_HOST="pg" \
    DATABASE_NAME="huginn_lite" \
    DATABASE_USERNAME="huginn" \
    DATABASE_PASSWORD="my-insecure-password" \
    DATABASE_RECONNECT="true"\
    DATABASE_PORT="5432"\
    DATABASE_ENCODING="utf8"\
    SMTP_DOMAIN="localhost"\
    SMTP_USER_NAME=""\
    SMTP_PASSWORD=""\
    SMTP_SERVER="mailcatcher"\
    SMTP_PORT="25"\
    SMTP_AUTHENTICATION="plain"\
    SMTP_ENABLE_STARTTLS_AUTO="false"\
    SMTP_SSL="false"\
    # Huggin-lite specifics
    DISABLE_APP="" \ 
    DISABLE_WORKER="" \ 
    DISABLE__ADDITIONAL_WORKER="" \
    DELAYED_JOB_MAX_RUNTIME=2\
    DELAYED_JOB_SLEEP_DELAY=10\
    APP_SECRET_TOKEN="my-insecure-token"
ENV PATH=$PATH:$ROOT/bin

WORKDIR $ROOT

RUN gem update --system && \
    gem install bundler --silent && \
    # Install dependencies:
    # - build-base: To ensure certain gems can be compiled
    # - python: To build and install nvm
    # - postgresql-dev postgresql-client: Communicate with postgres through the postgres gem
    # - libxslt-dev libxml2-dev: Nokogiri native dependencies
    # - imagemagick: for image processing
    # - git: for gemfiles using git 
    # - bash curl: to download nvm and install it
    # - libstdc++: to build NVM
    apk --update --no-cache add \
        build-base \
        tzdata \
        postgresql-dev postgresql-client \
        libxslt-dev libxml2-dev \
        imagemagick \
        git \
        bash curl \
        libstdc++ \
        && rm -rf /var/cache/apk/*
# Copy node binaries from node-alpine images
COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

COPY Gemfile* ./
COPY lib/gemfile_helper.rb ./lib/
COPY config/huginn.yml ./config/huginn.yml

RUN bundle config build.nokogiri --use-system-libraries
RUN gem install foreman
RUN bundle check || bundle install
RUN bundle binstubs --all

COPY . $ROOT
RUN SECRET_KEY_BASE=assets bundle exec rails assets:precompile
RUN mkdir -p /etc/supervisor/conf.d  && foreman export supervisord /etc/supervisor/conf.d

RUN rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -name "*.c" -delete && \
     find /usr/local/bundle/gems/ -name "*.o" -delete && \
     rm -rf node_modules app/assets vendor/assets lib/assets tmp/cache

FROM ruby:2.5.1-alpine
ARG BUNDLE_WITHOUT

ENV BUNDLER_VERSION=2.0.2\
    # Paths
    HOME=/home/huginn \
    ROOT=/home/huginn/app \ 
    RAILS_ROOT=/home/huginn/app \ 
    # Rails configuration
    RAILS_ENV=production \
    RACK_ENV=production\
    BUNDLE_WITHOUT=$BUNDLE_WITHOUT \
    RAILS_MAX_THREAD=25\
    RAILS_LOG_LEVEL="warn" \
    SECRET_KEY_BASE="insecure-secret" \
    RAILS_FORCE_SSL="enabled" \
    RAILS_SERVE_STATIC_FILES="false"\
    RAILS_PID_FILE="tmp/pids/server.pid" \
    RAILS_LOG_TO_STDOUT="true"\
    PORT=3000\
    DOCKER_EXPOSED_PORT=3000 \
    TIMEZONE="Europe/Zurich" \
    # Placeholders
    DATABASE_HOST="pg" \
    DATABASE_NAME="huginn_lite" \
    DATABASE_USERNAME="huginn" \
    DATABASE_PASSWORD="my-insecure-password" \
    DATABASE_RECONNECT="true"\
    DATABASE_PORT="5432"\
    DATABASE_ENCODING="utf8"\
    SMTP_DOMAIN="localhost"\
    SMTP_USER_NAME=""\
    SMTP_PASSWORD=""\
    SMTP_SERVER="mailcatcher"\
    SMTP_PORT="25"\
    SMTP_AUTHENTICATION="plain"\
    SMTP_ENABLE_STARTTLS_AUTO="false"\
    SMTP_SSL="false"\
    # Huggin-lite specifics
    DISABLE_APP="" \ 
    DISABLE_WORKER="" \ 
    DISABLE__ADDITIONAL_WORKER="" \
    DELAYED_JOB_MAX_RUNTIME=2\
    DELAYED_JOB_SLEEP_DELAY=10\
    APP_SECRET_TOKEN="my-insecure-token"

ENV PATH=$PATH:$ROOT/bin

LABEL contact.creator="hadrien@octree.ch"\
     contact.org="hello@octree.ch"\
     description="Huginn docker image."

RUN addgroup -S huginn -g 1001 && \
    adduser -S -g '' -u 1001 -G huginn huginn

RUN gem update --system && \
    gem install bundler && \
    apk add --no-cache \
        supervisor \
        python py-pip \
        postgresql-dev \
        tzdata \
        imagemagick \
        bash curl \
        vim \
        busybox-suid \
        && rm -rf /var/cache/apk/*

VOLUME /usr/local/bundle

WORKDIR $ROOT

COPY --from=build /etc/supervisor /etc/supervisor
COPY --from=build /usr/local/bundle/ /usr/local/bundle/
COPY --from=build $ROOT .
COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

EXPOSE 3000
VOLUME $ROOT/log
SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["entrypoints/docker-entrypoint.sh"]