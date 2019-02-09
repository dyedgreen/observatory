FROM alpine:3.8

RUN apk update \
    && apk add ruby \
           ruby-bigdecimal \
           ruby-bundler \
           ruby-io-console \
           ruby-irb \
           ca-certificates \
           libressl \
           less \
    && apk add --virtual build-dependencies \
           build-base \
           ruby-dev \
           libressl-dev \
    && apk add sqlite sqlite-dev sqlite-libs

WORKDIR /usr/var/app

COPY Gemfile .
RUN bundle install
RUN gem cleanup \
    && rm -rf /usr/lib/ruby/gems/*/cache/* \
          /var/cache/apk/* \
          /tmp/* \
          /var/tmp/*

COPY . .
ENV session_secret "make_sure_to_set_in_docker_compose"
EXPOSE 80

CMD ["rackup", "-p", "80", "-o", "0.0.0.0"]
