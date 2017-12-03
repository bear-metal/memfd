FROM ruby:2.4
RUN mkdir /memfd
WORKDIR /memfd
# bundle
ADD Gemfile /memfd/Gemfile
ADD Gemfile.lock /memfd/Gemfile.lock
ADD memfd.gemspec /memfd/memfd.gemspec
ADD lib/memfd/version.rb /memfd/lib/memfd/version.rb
RUN bundle install
# run tests
ADD . /memfd
CMD bundle exec rake bench
