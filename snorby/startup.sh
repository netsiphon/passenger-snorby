#!/bin/bash
# https://github.com/Snorby/snorby/blob/master/README.md

export PATH=$PATH:/usr/local/rvm/rubies/ruby-2.2.1-p85/bin

# Password storage
printf "[client]\npassword=%s" "$DB_PASSWORD" > ~/.my.cnf
chmod 600 ~/.my.cnf

mysql -u $DB_USER -h $DB_HOST -e " \
CREATE IF NOT EXISTS DATABASE snorby; \
GRANT ALL on snorby.* to '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'; \
FLUSH PRIVILEGES;"

# Modify Configs

# database.yml
sed_output="$(cat "$SNORBY_PATH/config/database.yml" | sed 's|$DB_HOST|'$DB_HOST'|g' | \
sed 's|$DB_PORT|'$DB_PORT'|g' | sed 's|$DB_USER|'$DB_USER'|g' | \
sed 's|$DB_PASSWORD|'$DB_PASSWORD'|g')"
printf "%s" "$sed_output" > "$SNORBY_PATH/config/database.yml"
sed_output=""

# passenger.conf
sed_output="$(cat "/etc/httpd/conf.d/passenger.conf" | sed 's|$SNORBY_HOST|'$SNORBY_HOST'|g' | \
sed 's|$SNORBY_PORT|'$SNORBY_PORT'|g' | sed 's|$SNORBY_PATH|'$SNORBY_PATH'|g')"
printf "%s" "$sed_output" > "/etc/httpd/conf.d/passenger.conf"
sed_output=""

# PassengerRoot
passenger_root="$(passenger-config --root)"
# Check httpd config for value and remove any existing
sed_output="$(cat "/etc/httpd/conf/httpd.conf" | sed 's|^PassengerRoot.*$||g')"
printf "%s\nPassengerRoot %s" "$sed_output" "$passenger_root"  > "/etc/httpd/conf/httpd.conf"
sed_output=""

# Setup Snorby
cd "$SNORBY_PATH"
/bin/bash -l -c "bundle exec rake snorby:setup"

# GO!
cd "$SNORBY_PATH"
# Not necessary with Passenger!
#/bin/bash -l -c "rails server -e production"

# Delayed Jobs start still needed though
/bin/bash -l -c "rails runner Snorby::Worker.start"
/bin/bash -l -c "rails runner Snorby Cache Jobs"

# Run HTTPD
/bin/bash -l -c "/usr/sbin/httpd -D FOREGROUND"
