FROM ruby:3.3.4-slim-bullseye

LABEL org.opencontainers.image.authors="@puppetlabs/release-engineering"
LABEL org.opencontainers.image.title="vmfloaty"
LABEL org.opencontainers.image.source=https://github.com/puppetlabs/vmfloaty
LABEL org.opencontainers.image.description="A CLI helper tool for VMPooler"

RUN apt-get update -qq && apt-get install -y build-essential less make openssh-client

RUN groupadd --gid 1000 floatygroup \
    && useradd --uid 1000 --gid 1000 -m floatyuser

USER floatyuser

WORKDIR /home/floatyuser/app
COPY --chown=floatyuser:floatygroup . .

RUN gem install bundler \
  && bundle install \
  && gem build vmfloaty.gemspec \
  && gem install vmfloaty*.gem

ENTRYPOINT [ "floaty" ]
