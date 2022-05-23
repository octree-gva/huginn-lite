ARG NODE_VERSION=14.16.1
FROM node:$NODE_VERSION-alpine AS node
FROM ruby:2.5.1-alpine as build
ENV BUNDLER_VERSION=2.0.2\
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    HOME=/home/huginn\
    ROOT=/home/huginn/app\
    RAILS_ENV=production \
    RACK_ENV=production
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
        python \
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

RUN bundle config build.nokogiri --use-system-libraries && \
    bundle config set without 'development test'

RUN bundle check || bundle install --quiet 
RUN bundle binstubs --all

COPY . $ROOT
RUN SECRET_KEY_BASE=assets bundle exec rails assets:precompile

RUN mkdir -p /etc/supervisor/conf.d && \
    mv -f entrypoints/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -name "*.c" -delete && \
     find /usr/local/bundle/gems/ -name "*.o" -delete && \
     rm -rf node_modules app/assets vendor/assets lib/assets tmp/cache
RUN touch supervisord.log

FROM ruby:2.5.1-alpine
ENV BUNDLER_VERSION=2.0.2\
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    RAILS_ROOT=/home/huginn/app \ 
    ROOT=/home/huginn/app \ 
    HOME=/home/huginn \
    RAILS_ENV=production \
    RACK_ENV=production\
    DATABASE_HOST="pg" \
    DATABASE_USERNAME="huginn" \
    DATABASE_PASSWORD="my-insecure-password" \
    DATABASE_DATABASE="huginn" \
    PORT=3000\
    DOCKER_EXPOSED_PORT=3000 \
    RAILS_MAX_THREAD=25\
    RAILS_FORCE_SSL="enabled" \
    RAILS_SERVE_STATIC_FILES="false"\
    SECRET_KEY_BASE="insecure-secret" \
    TZ="Europe/Zurich" \
    RAILS_PID_FILE="tmp/pids/server.pid" \
    RAILS_SERVE_STATIC_FILES="disabled" \
    RAILS_LOG_LEVEL="warn" \
    SMTP_AUTHENTICATION="plain"\
    SMTP_USERNAME=""\
    SMTP_PASSWORD="" \
    SMTP_ADDRESS="mailcatcher" \
    SMTP_DOMAIN="localhost" \
    SMTP_STARTTLS_AUTO="enabled"\
    SMTP_VERIFY_MODE="none"\
    DISABLE_APP="" \ 
    DISABLE_WORKER="" \ 
    DISABLE__ADDITIONAL_WORKER="" 
LABEL contact.creator="hadrien@octree.ch"\
     contact.org="hello@octree.ch"\
     description="Huginn docker image."

WORKDIR $ROOT
RUN addgroup -S huginn -g 1002 && \
    adduser -S -g '' -u 1002 -G huginn huginn 
RUN gem update --system && \
    gem install bundler && \
    apk add --no-cache \
        supervisor \        
        postgresql-dev \
        tzdata \
        imagemagick \
        bash \
        vim \
        busybox-suid \
        && rm -rf /var/cache/apk/* && \
    # Set again bundle config, to have bundle check working
    bundle config set without 'development test'

VOLUME /usr/local/bundle
COPY --from=build /etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --from=build /usr/local/bundle/ /usr/local/bundle/

COPY --from=build $ROOT .
EXPOSE 3000
VOLUME $ROOT/log
SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["entrypoints/docker-entrypoint.sh"]
