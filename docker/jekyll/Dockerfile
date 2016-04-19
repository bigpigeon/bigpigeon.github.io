FROM ruby:2.1

RUN gem install jekyll
RUN gem install redcarpet -v 3.2.0
RUN gem install mini_portile2
RUN gem install webrick

RUN mkdir /data
VOLUME ["/var/www/html"]