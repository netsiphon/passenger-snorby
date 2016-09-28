#!/bin/bash
# https://github.com/Snorby/snorby/blob/master/README.md

export PATH=$PATH:/usr/local/rvm/rubies/ruby-2.2.1-p85/bin

# Password storage
printf "[client]\npassword=%s" "$DB_PASSWORD" > ~/.my.cnf
chmod 600 ~/.my.cnf

mysql -u $DB_USER -h $DB_HOST -e " \
CREATE DATABASE IF NOT EXISTS snorby; \
GRANT ALL on snorby.* to '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'; \
FLUSH PRIVILEGES;"

# Modify Configs

# database.yml
sed_output="$(cat "$SNORBY_PATH/config/database.yml" | sed 's|$DB_HOST|'$DB_HOST'|g' | \
sed 's|$DB_PORT|'$DB_PORT'|g' | sed 's|$DB_USER|'$DB_USER'|g' | \
sed 's|$DB_PASSWORD|'$DB_PASSWORD'|g')"
printf "%s" "$sed_output" > "$SNORBY_PATH/config/database.yml"
sed_output=""

# PassengerRoot
PASSENGER_ROOT="$(passenger-config --root)"

# passenger.conf
sed_output="$(cat "/etc/httpd/conf.d/passenger.conf" | sed 's|$SNORBY_HOST|'$SNORBY_HOST'|g' | \
sed 's|$SNORBY_PORT|'$SNORBY_PORT'|g' | sed 's|$SNORBY_PATH|'$SNORBY_PATH'|g' | \
sed 's|$PASSENGER_ROOT|'$PASSENGER_ROOT'|g')"
printf "%s" "$sed_output" > "/etc/httpd/conf.d/passenger.conf"
sed_output=""

# Setup Snorby
cd "$SNORBY_PATH"
/bin/bash -l -c "bundle exec rake snorby:setup"

# Fix PDF warnings as per README.md
sed_output="$(cat /usr/local/rvm/gems/ruby-2.2.1/cache/bundler/gems/ezprint-*/lib/ezprint/railtie.rb | sed 's/\(^.*\)\(Mime::Type.register.*application\/pdf.*$\)/\1if Mime::Type.lookup_by_extension(:pdf) != "application\/pdf"\n\1  \2\n\1end/')"
printf "%s" "$sed_output" > /usr/local/rvm/gems/ruby-2.2.1/cache/bundler/gems/ezprint-*/lib/ezprint/railtie.rb
sed_output=""
sed_output="$(cat /usr/local/rvm/gems/ruby-2.2.1/gems/actionpack-*/lib/action_dispatch/http/mime_types.rb | sed 's/\(^.*\)\(Mime::Type.register.*application\/pdf.*$\)/\1if Mime::Type.lookup_by_extension(:pdf) != "application\/pdf"\n\1  \2\n\1end/')"
printf "%s" "$sed_output" > /usr/local/rvm/gems/ruby-2.2.1/gems/actionpack-*/lib/action_dispatch/http/mime_types.rb
sed_output=""
sed_output="$(cat /usr/local/rvm/gems/ruby-2.2.1/gems/railties-*/guides/source/action_controller_overview.textile | sed 's/\(^.*\)\(Mime::Type.register.*application\/pdf.*$\)/\1if Mime::Type.lookup_by_extension(:pdf) != "application\/pdf"\n\1  \2\n\1end/')"
printf "%s" "$sed_output" > /usr/local/rvm/gems/ruby-2.2.1/gems/railties-*/guides/source/action_controller_overview.textile
sed_output=""

# Fix Login Issue (No load after login) until patch committed - https://github.com/notnyt/snorby/commit/697ae8abaa9a61b42da4f3849b039b373abf2295
sed_output="$(cat "$SNORBY_PATH/app/views/layouts/login.html.erb" | sed 's|var snorby_url|var baseuri|g')"
printf "%s" "$sed_output" > "$SNORBY_PATH/app/views/layouts/login.html.erb"
sed_output=""
sed_output="$(cat "$SNORBY_PATH/public/javascripts/snorby.js" | sed 's|var snorby_url|var baseuri|g')"
printf "%s" "$sed_output" > "$SNORBY_PATH/public/javascripts/snorby.js"
sed_output=""

# Refresh Snorby
cd "$SNORBY_PATH"
/bin/bash -l -c "bundle exec rake snorby:refresh"

# GO!
cd "$SNORBY_PATH"
# Delayed Jobs start still needed though
/bin/bash -l -c "rails runner Snorby::Worker.start"
/bin/bash -l -c "rails runner Snorby Cache Jobs"

# Run HTTPD in CMD in Dockerfile
/bin/bash -l -c "/usr/sbin/httpd -D FOREGROUND"
