FROM centos:centos7
MAINTAINER Joseph Kennedy <joseph@netsiphon.com>

#Environment Variables
ENV SNORBY_PATH=/usr/local/snorby
ENV SNORBY_PORT=9443
ENV SNORBY_HOSTNAME=localhost
ENV DB_HOST=localhost
ENV DB_PORT=3306
ENV DB_USER=snorby
ENV DB_PASSWORD=password
ENV SNORBY_CONFIG=$SNORBY_PATH/config/snorby_config.yml

# Update only please
RUN \
    yum update -y
# Install Required Packages from Yum
RUN \
    yum install -y epel-release yum-utils && \
    yum install -y pygpgme curl wget tar git wkhtmltopdf libxml2-devel libxslt-devel && \
    yum install -y httpd && \
    # Passenger Repo
    sudo curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo && \
    sudo yum install -y mod_passenger
# Setup Snorby 
RUN \
    sudo systemctl restart httpd && \
    # Prepare ruby for Snorby
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
    curl -sSL https://get.rvm.io | bash -s stable --ruby=1.9.3 && \
    source /usr/local/rvm/scripts/rvm && \
    source /etc/profile.d/rvm.sh && \
    #Ruby Path
    export PATH=$PATH:/usr/local/rvm/rubies/ruby-1.9.3-p551/bin && \
    gem update --system && \
    gem install bundler && \
    # Get Latest Snorby
    git clone git://github.com/Snorby/snorby.git /usr/local/snorby && \
    cd /usr/local/snorby && bundle install

COPY snorby /

VOLUME [ "{$volume-container}:{$SNORBY_PATH}" ]

EXPOSE $SNORBY_PORT

ENTRYPOINT ["/startup.sh"]