#!/bin/bash
#https://stackoverflow.com/questions/37836764/run-command-in-docker-container-only-on-the-first-start
set -e
if [ -z "$RAILS_ENV" ]; then
  RAILS_ENV_TEMP="production"
else
  RAILS_ENV_TEMP=$RAILS_ENV
fi

# DECIDIM_PATH is defined by an ENV command in the backing Dockerfile
decidim_init_file=${DECIDIM_PATH}/config/initializers/decidim.rb

cd ${DECIDIM_PATH}

admin_email=${ADMIN_EMAIL}
admin_password=${ADMIN_PASSWORD}

function db_create() {
  if [[ "$RAILS_ENV_TEMP" == "production" ]]; then
      echo "**************************************"
      echo "********** ENV_PRODUCTION ************"
      echo "**************************************"
      rails db:create db:migrate RAILS_ENV=production
      rails assets:precompile db:migrate RAILS_ENV=production
  else
      echo "**************************************"
      echo "********* ENV_DEVELOPEMENT ***********"
      echo "**************************************"
      rails db:create db:migrate #db:seed
  fi
}

function db_create_admin() {
  #rails runner "
  #  user = Decidim::System::Admin.new(email: '${admin_email}', password: '${admin_password}', password_confirmation: '${admin_password}')
  #  user.try(:save!)"
  rails runner "
  begin
    Decidim::System::Admin.create!(
    email: '${admin_email}',
    password: '${admin_password}',
    password_confirmation: '${admin_password}')
  rescue ActiveRecord::RecordInvalid => e
    print e
  end"
}

function check_locales() {
  rails decidim:check_locales
}

function update() {
  bundle update decidim
  rails decidim:upgrade
  rails db:migrate
  rails decidim:check_locales
}

function seed_data() {
  SEED=true rails db:seed
}

function default_locale() {
  sed -i -e 's|config.default_locale.*$|config.default_locale = :'${DEFAULT_LOCALE}'|' ${decidim_init_file}
}
function default_locales_available() {
  sed -i -e 's|config.available_locales.*$|config.available_locales = '${DEFAULT_LOCALES_AVAILABLE}'|' ${decidim_init_file}
}

# Continuously provide logs so that 'docker logs' can produce them
tail -F ${DECIDIM_PATH}/log/development.log &
tail -F ${DECIDIM_PATH}/log/production.log &

CONTAINER_ALREADY_STARTED="CONTAINER_ALREADY_STARTED_PLACEHOLDER"
if [ ! -e $CONTAINER_ALREADY_STARTED ]; then
    touch $CONTAINER_ALREADY_STARTED
    echo "-- First container startup --"

    if [[ "$DB_CREATE" == "true" ]]; then
        echo "**************************************"
        echo "************* DB_CREATE **************"
        echo "**************************************"
        db_create
    fi

    if [[ "$DB_SEED_DATA" == "true" ]]; then
        echo "**************************************"
        echo "************ DB_SEED_DAT *************"
        echo "**************************************"
        seed_data
    fi

    if [[ "$ADMIN_ENABLE" == "true" ]]; then
        echo "**************************************"
        echo "*********** ADMIN_ENABLE *************"
        echo "**************************************"
        db_create_admin
    fi

    if [[ "$DECIDIM_UPDATE" == "true" ]]; then
        echo "**************************************"
        echo "********** DECIDIM_UPDATE ************"
        echo "**************************************"
        update
    fi

    if [[ -z "${DEFAULT_LOCALE}" ]]; then
        echo "No DEFAULT_LOCALE"
    else
        echo "**************************************"
        echo "********** DEFAULT_LOCALE ************"
        echo "**************************************"
        default_locale
    fi

    if [[ -z "${DEFAULT_LOCALES_AVAILABLE}" ]]; then
        echo "No DEFAULT_LOCALES_AVAILABLE"
    else
        echo "**************************************"
        echo "***** DEFAULT_LOCALES_AVAILABLE ******"
        echo "**************************************"
        default_locales_available
    fi

else
    echo "-- Not first container startup. Delete file \"CONTAINER_ALREADY_STARTED_PLACEHOLDER\" if you want to run the initialization process. --"
fi

if [ "$1" = "db_create" ]; then
	db_create
elif [ "$1" = "db_create_admin" ]; then
	db_create_admin
elif [ "$1" = "check_locales" ]; then
	check_locales
elif [ "$1" = "update" ]; then
	update
elif [ "$1" = "seed_data" ]; then
	seed_data
else
	bundle exec puma
fi
