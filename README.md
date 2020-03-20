# Docker to use [Decidim](https://decidim.org/)

Docker image to deploy [Decidim](https://decidim.org/).

This docker image is based on [ruby:2.6.5](https://hub.docker.com/_/ruby).
It includes the packages needed to run [Decidim](https://github.com/decidim/decidim) (Especially [NodeJS](https://nodejs.org/)). The Decidim application is installed in folder `/app` and can be find in environment variable `DECIDIM_PATH`.

-   [Getting Started](#getting-started)
    -   [Prerequisities](#prerequisities)
    -   [Quickstart Demo](#quickstart-demo)
    -   [Quickstart](#quickstart)
-   [Environment Variables](#environment-variables)
-   [Example : Run production version with external initialization
    script](#example--run-production-version-with-external-initialization-script)
-   [Example : Run development
    version](#example--run-development-version)
-   [Authors](#authors)
-   [License](#license)

## Getting Started

### Prerequisities

In order to run this container you'll need docker installed.

* [Windows](https://docs.docker.com/windows/started)
* [OS X](https://docs.docker.com/mac/started/)
* [Linux](https://docs.docker.com/linux/started/)

### Quickstart Demo

To run a simple example, you can use the file `docker-compose-demo.yml`

```
version: '3'
services:
  app:
    image: pcourbin/decidim:0.20.0
    environment:
      - DATABASE_HOST=pg
      - DATABASE_USERNAME=decidim
      - DATABASE_PASSWORD=pgpassword
      - RAILS_ENV=development
      - DB_CREATE=true
      - DB_SEED_DATA=true
    ports:
      - 3000:3000
    links:
      - pg

  pg:
    image: postgres
    environment:
      - POSTGRES_USER=decidim
      - POSTGRES_PASSWORD=pgpassword
```
and run
```
docker-compose -f docker-compose-demo.yml up
```
Then, go to http://localhost:3000 (after a long wait due to creation of seed data, you can check the logs `docker-compose -f docker-compose-demo.yml logs -f`) and login with the users defined for [`seed data` by Decidim](https://docs.decidim.org/develop/en/getting_started/):

| Path | User | Password | Description |
| --- | --- | --- |--- |
| http://localhost:3000/system | system@example.org | decidim123456 | A Decidim::System::Admin to log in at /system. |
| http://localhost:3000 | admin@example.org | decidim123456 | A Decidim::User acting as an admin for the organization. |
| http://localhost:3000 | user@example.org | decidim123456 | A Decidim::User that also belongs to the organization but it’s a regular user. |

Be careful, this a demo/test example. You can create a new organization, but you will not receive any email, even if you configure the SMTP server on the organization configuration page. So you will not be able to confirm any administrator or new user.

### Quickstart

To run a full functional version, you can use the file `docker-compose-prod.yml`.
Be careful to change the `<SMTP>` settings.

```
version: '3'
services:
  app:
    image: pcourbin/decidim:0.20.0
    environment:
      - DATABASE_URL=postgres://decidim:pgpassword@pg/app_production
      - RAILS_SERVE_STATIC_FILES=true # If RAILS_ENV=production and you don't have NGINX before requests
      - RAILS_ENV=production
      - DB_CREATE=true
      - ADMIN_ENABLE=true
      - ADMIN_EMAIL=admin@mydecidim.org
      - ADMIN_PASSWORD=myadminpassword
      - DEFAULT_LOCALE=en
      - 'DEFAULT_LOCALES_AVAILABLE=[:en,:fr,:es,:de,:it,:ca]'
      - REDIS_URL=redis://redis:6379
      - SECRET_KEY_BASE=my_secret_key_base
      - SMTP_USERNAME=<YOUR_SMTP_USER>
      - SMTP_PASSWORD=<YOUR_SMTP_PASSWORD>
      - SMTP_ADDRESS=<YOUR_SMTP_HOST>
      - SMTP_DOMAIN=<YOUR_SMTP_DOMAIN>
    ports:
      - 3000:3000
    links:
      - pg
      - redis
    restart: always

  pg:
    image: postgres
    environment:
      - POSTGRES_USER=decidim
      - POSTGRES_PASSWORD=pgpassword
    volumes:
      - pg-data:/var/lib/postgresql/data
    restart: always

  redis:
    image: redis
    volumes:
      - redis-data:/data
    restart: always

volumes:
  pg-data: {}
  redis-data: {}
```
and run
```
docker-compose -f docker-compose-prod.yml up
```
Then, go to http://localhost:3000/system (after a long wait due to creation of static assets, you can check the logs `docker-compose -f docker-compose-prod.yml logs -f`) and login with the users defined in `ADMIN_EMAIL` and `ADMIN_PASSWORD`.

You can then create your own organization. If you do not fill in the SMTP parameters in the organization creation form, the parameters defined in your `docker-compose-prod.yml` file will be used.

Be careful, when you create your organization, an email is sent to your first administrator. This email gives you a link to http://localhost/users/invitation/, do not forget to add the port used by your docker, i.e. here: http://localhost:3000/users/invitation/

## Environment Variables

| Name | Possibles values | Description |
| --- | --- |--- |
| `RAILS_ENV` | `development`, `production` | |
| `DATABASE_URL` | `postgres://USER:PASSWORD@HOST/DB_NAME` | Used if `RAILS_ENV=production` to connect to your postgresql database. |
| `DATABASE_HOST` | * | Used if `RAILS_ENV=development`, host of your postgresql database. |
| `DATABASE_USERNAME` | * | Used if `RAILS_ENV=development`, username of your postgresql database. |
| `DATABASE_PASSWORD` | * | Used if `RAILS_ENV=development`, password of your postgresql database link with `DATABASE_USERNAME`. |
| `RAILS_SERVE_STATIC_FILES` | `true` | Used if `RAILS_ENV=production` and you don't have NGINX before requests. If not, you will have "MIME type errors". Be careful, do not define this environment variable if you do not need it. It will not test the value of the environment variable but only if the variable exists. |
| `DB_CREATE` | `true`, * | If `true`, it will create the database. See [decidim.sh](decidim.sh) for details. |
| `ADMIN_ENABLE` | `true`, * | If `true`, it will create a default Decidim::System::Admin user. See [decidim.sh](decidim.sh) for details. |
| `ADMIN_EMAIL` | * | If `ADMIN_ENABLE=true`, email of the default Decidim::System::Admin user created. See [decidim.sh](decidim.sh) for details. |
| `ADMIN_PASSWORD` | * | If `ADMIN_ENABLE=true`, password of the default Decidim::System::Admin user created. See [decidim.sh](decidim.sh) for details. |
| `DB_SEED_DATA` | `true`, * | If `true`, it will create seed datas from Decidim, see details [here](https://docs.decidim.org/develop/en/getting_started/). Be careful ! It may work only if `DEFAULT_LOCALE=en`, see [here](https://github.com/decidim/decidim/issues/4667). See [decidim.sh](decidim.sh) for details. |
| `DEFAULT_LOCALE` | See [Decidim locales](https://github.com/decidim/decidim/tree/master/decidim-pages/config/locales) | Default locale used for Decidim. |
| `DEFAULT_LOCALES_AVAILABLE` | See [Decidim locales](https://github.com/decidim/decidim/tree/master/decidim-pages/config/locales) | Default locales available for Decidim. Be careful, you must enter a list like `'DEFAULT_LOCALES_AVAILABLE=[:en,:fr,:es,:de,:it,:ca]'`|
| `REDIS_URL` | `redis://HOST:PORT` | Path to your [REDIS](https://redis.io/) server. |
| `SECRET_KEY_BASE` | * | This secret key is used for verifying the integrity of signed cookies. |
| `SMTP_USERNAME` | * | Used if `RAILS_ENV=production`, username of your SMTP server. |
| `SMTP_PASSWORD` | * | Used if `RAILS_ENV=production`, password of your SMTP server linked with `SMTP_USERNAME`. |
| `SMTP_ADDRESS` | * | Used if `RAILS_ENV=production`, host of your SMTP server. |
| `SMTP_DOMAIN` | * | Used if `RAILS_ENV=production`, domain of your SMTP server. |

## Example : Run production version with external initialization script
To run a full version, you can use the next `docker-compose.yml` file and edit `<SMTP>` settings.
```
version: '3'
services:
  app:
    image: pcourbin/decidim:0.20.0
    environment:
      - DATABASE_URL=postgres://decidim:pgpassword@pg/app_production
      - RAILS_SERVE_STATIC_FILES=true
      - RAILS_ENV=production
      - REDIS_URL=redis://redis:6379
      - SECRET_KEY_BASE=my_secret_key_base
      - SMTP_USERNAME=<YOUR_SMTP_USER>
      - SMTP_PASSWORD=<YOUR_SMTP_PASSWORD>
      - SMTP_ADDRESS=<YOUR_SMTP_HOST>
      - SMTP_DOMAIN=<YOUR_SMTP_DOMAIN>
    ports:
      - 3000:3000
    links:
      - pg
      - redis
    restart: always

  pg:
    image: postgres
    environment:
      - POSTGRES_USER=decidim
      - POSTGRES_PASSWORD=pgpassword
    restart: always

  redis:
    image: redis
    restart: always
```
it will prepare a Decidim App wihtout any database creation or user admin creation.

Then, you can use the following line to execute what you want inside the Decidim APP.
```
docker-compose -f docker-compose.yml exec app sh -c '<YOUR COMMAND>'
```

See script [config-decidim.sh](config-decidim.sh) to execute some default commands such as
```
.\config-decidim.sh edit_init_decidim docker-compose.yml
```
which will open the Decidim configuration file `config/initializers/decidim.rb`, let you edit it, and finally restart the Decidim APP.

## Example : Run development version
TO DO

## Authors
* **Pierre Courbin** - *Initial work* - [PCourbin](https://github.com/pcourbin)

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
