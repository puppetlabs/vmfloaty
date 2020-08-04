FROM ruby:2.7

COPY ./ ./

RUN apt-get update && apt-get install -y less
RUN gem install bundler && bundle install && gem build vmfloaty.gemspec && gem install vmfloaty*.gem
