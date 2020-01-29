#!/bin/bash
set -e

admin_email="admin@mydecidim.org"
admin_password="myadminpassword"

function db_create() {
  #docker-compose exec app sh -c 'cd '${APP_PATH}' && rails db:create db:migrate db:seed'
  docker-compose exec app sh -c 'rails db:create db:migrate db:seed'
}

function db_create_admin() {
  docker-compose exec app sh -c "rails runner ' \
    email = \"'${admin_email}'\"
    password = \"'${admin_password}'\"
    user = Decidim::System::Admin.new(email: email, password: password, password_confirmation: password)
    user.save!'"
}

function check_locales() {
  docker-compose exec app sh -c 'rails decidim:check_locales'
}

function upgrade() {
  docker-compose exec app sh -c 'bundle update decidim && \
  rails decidim:upgrade && \
  rails db:migrate && \
  rails decidim:check_locales'
}

function seed_data() {
  docker-compose exec app sh -c 'SEED=true rails db:seed'
}

function edit_init_decidim() {
  docker-compose exec app sh -c 'nano config/initializers/decidim.rb'
  docker-compose restart app
}



if [ "$1" = "db_create" ]; then
	db_create
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
	echo "Error: db_create, db_create_admin, check_locales, seed_data, upgrade, edit_init_decidim !"
fi
