#!/bin/bash
#https://github.com/Snorby/snorby/blob/master/README.md

export PATH=$PATH:/usr/local/rvm/rubies/ruby-2.2.1-p85/bin

cat /etc/hosts

mysql -u $DB_USER -p $DB_PASSWORD -h $DB_HOST -e " \
CREATE IF NOT EXISTS DATABASE snorby; \
GRANT ALL on snorby.* to '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'; \
FLUSH PRIVILEGES;"

#Modify Configs
sed -i 's/$DB_HOST/'$DB_HOST'/g' $SNORBY_PATH/config/database.yml
sed -i 's/$DB_PORT/'$DB_PORT'/g' $SNORBY_PATH/config/database.yml
sed -i 's/$DB_USER/'$DB_USER'/g' $SNORBY_PATH/config/database.yml
sed -i 's/$DB_PASSWORD/'$DB_PASSWORD'/g' $SNORBY_PATH/config/database.yml

sed -i 's/$SNORBY_HOST/'$SNORBY_HOST'/g' /etc/httpd/conf.d/passenger.conf
sed -i 's/$SNORBY_PORT/'$SNORBY_PORT'/g' /etc/httpd/conf.d/passenger.conf
sed -i 's/$SNORBY_PATH/'$SNORBY_PATH'/g' /etc/httpd/conf.d/passenger.conf

#Snort Rules at some point...

#Setup Snorby
cd $SNORBY_PATH
/bin/bash -l -c "bundle exec rake snorby:setup"


# GO!
cd $SNORBY_PATH
#Not necessary with Passenger!
#/bin/bash -l -c "rails server -e production"

#Delayed Jobs start still needed though
/bin/bash -l -c "rails runner Snorby::Worker.start"
/bin/bash -l -c "rails runner Snorby Cache Jobs"
