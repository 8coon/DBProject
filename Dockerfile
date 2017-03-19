FROM ubuntu:16.04

MAINTAINER Serge Peshkoff


RUN apt-get -y update

ENV PGVER 9.5
RUN apt-get install -y postgresql-$PGVER

USER postgres

RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker &&\
    /etc/init.d/postgresql stop

RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/$PGVER/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/$PGVER/main/postgresql.conf

EXPOSE 5432
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]
USER root


RUN apt-get install -y ruby
RUN apt-get install -y ruby-bundler
RUN apt-get install -y ruby-dev

RUN apt-get install -y build-essential bison openssl libreadline6
RUN apt-get install -y libreadline6-dev curl git-core zlib1g zlib1g-dev
RUN apt-get install -y libssl-dev libyaml-dev libxml2-dev autoconf libc6-dev
RUN apt-get install -y ncurses-dev automake libtool libgmp-dev libgmp3-dev
RUN apt-get install -y libpq-dev


ENV APP_HOME /usr/app
ENV HOME /root

RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/

RUN /bin/bash -c -l -s "bundle install"

ADD . $APP_HOME

ENV DB "postgresql://docker:docker@localhost/docker"
ENV PORT 5000
EXPOSE 5000

CMD ["/bin/bash", "-l", "-c", "service postgresql start && ruby main.rb"]





