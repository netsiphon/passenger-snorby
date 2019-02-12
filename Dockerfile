FROM centos:centos7
MAINTAINER Joseph Kennedy <joseph@netsiphon.com>

#Environment Variables
ENV SNORBY_PATH="/usr/local/snorby"
ENV SNORBY_PORT="9443"
ENV SNORBY_HOST="localhost"
ENV DB_PORT="3306"
ENV DB_HOST=mysql
ENV DB_USER="snorby"
ENV DB_PASSWORD="password"
ENV SNORBY_CONFIG="$SNORBY_PATH/config/snorby_config.yml"
ENV RAILS_ENV=production
ENV VOLUME_CONTAINER=""
ENV RUBY_VERSION="2.3.8"

# Update only please
RUN yum update -y
# Install Required Packages from Yum
RUN yum install -y epel-release yum-utils
RUN \
    yum install -y pygpgme curl wget tar git wkhtmltopdf libxml2-devel libxslt-devel mariadb mariadb-devel mariadb-libs && \
    yum install -y httpd openssl mod_ssl postgresql postgresql-devel java
RUN \
    # Passenger Repo
    curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo
RUN yum install -y mod_passenger
# Setup Snorby
RUN \
    # Prepare ruby for Snorby
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    source /usr/local/rvm/scripts/rvm && \
    source /etc/profile.d/rvm.sh && \
    /bin/bash -l -c "rvm install $RUBY_VERSION" && \
    /bin/bash -l -c "rvm use $RUBY_VERSION" && \
    #Ruby Path
    export PATH=$PATH:/usr/local/rvm/rubies/ruby-$RUBY_VERSION/bin
RUN /bin/bash -l -c "gem update --system --no-document" && \
    /bin/bash -l -c "gem install bundler --no-document"
RUN \
    # Get Latest Snorby
    git clone git://github.com/Snorby/snorby.git /usr/local/snorby && \
    cd /usr/local/snorby && \
    /bin/bash -l -c "bundle install --full-index"

COPY snorby /

EXPOSE 9443

ENTRYPOINT ["./startup.sh"]
