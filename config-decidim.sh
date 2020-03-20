#!/bin/bash
set -e

if [ -z "$2" ]; then
  DOCKER_COMPOSE_FILE=docker-compose-dev.yml
else
  DOCKER_COMPOSE_FILE=$2
fi

admin_email="admin@mydecidim.org"
admin_password="myadminpassword"

function db_create() {
  docker-compose -f ${DOCKER_COMPOSE_FILE} exec app sh -c 'rails db:create db:migrate'
}

function assets_precompile_prod() {
  docker-compose -f ${DOCKER_COMPOSE_FILE} exec app sh -c 'rails assets:precompile db:migrate'
}

function db_create_admin() {
  docker-compose -f ${DOCKER_COMPOSE_FILE} exec app sh -c "rails runner ' \
    email = \"'${admin_email}'\"
    password = \"'${admin_password}'\"
    user = Decidim::System::Admin.new(email: email, password: password, password_confirmation: password)
    user.save!'"
}

function check_locales() {
  docker-compose -f ${DOCKER_COMPOSE_FILE} exec app sh -c 'rails decidim:check_locales'
}

function upgrade() {
  docker-compose -f ${DOCKER_COMPOSE_FILE} exec app sh -c 'bundle update decidim && \
  rails decidim:upgrade && \
  rails db:migrate && \
  rails decidim:check_locales'
}

function seed_data() {
  docker-compose -f ${DOCKER_COMPOSE_FILE} exec app sh -c 'SEED=true rails db:seed'
}

function edit_init_decidim() {
  docker-compose -f ${DOCKER_COMPOSE_FILE} exec app sh -c 'nano config/initializers/decidim.rb'
  docker-compose -f ${DOCKER_COMPOSE_FILE} restart app
}



if [ "$1" = "db_create" ]; then
	db_create
elif [ "$1" = "assets_precompile_prod" ]; then
	db_create_prod
elif [ "$1" = "db_create_admin" ]; then
	db_create_admin
elif [ "$1" = "check_locales" ]; then
	check_locales
elif [ "$1" = "upgrade" ]; then
	upgrade
elif [ "$1" = "seed_data" ]; then
	seed_data
elif [ "$1" = "edit_init_decidim" ]; then
	edit_init_decidim
else
	echo "Error: db_create, assets_precompile_prod, db_create_admin, check_locales, seed_data, upgrade, edit_init_decidim !"
fi
