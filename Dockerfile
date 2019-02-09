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
    && apk add sqlite sqlite-dev sqlite-libs \
\
    && gem install puma --no-rdoc --no-ri \
    && gem install rerun --no-rdoc --no-ri \
    && gem install scorched --no-rdoc --no-ri \
    && gem install sqlite3 --no-rdoc --no-ri \
\
    && gem cleanup \
    && apk del build-dependencies \
    && rm -rf /usr/lib/ruby/gems/*/cache/* \
          /var/cache/apk/* \
          /tmp/* \
          /var/tmp/*

WORKDIR /usr/var/app

COPY Gemfile .
RUN bundle install

COPY . .
ENV session_secret "make_sure_to_set_in_docker_compose"
EXPOSE 80

CMD ["rackup", "-p", "80", "-o", "0.0.0.0"]
