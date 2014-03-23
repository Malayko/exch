# **Bitfication**

**Bitfication** powers the Exchange bitfication.com, a Bitcoin Trading Platform, and it is is powered by Ubuntu Linux!

Features:

* Open Source

* Based on Ruby on Rails

* Fully localizable

* Multi-currency (under development)

## Installation on top of Ubuntu 12.04.4 LTS

Run the following commands as 'root' and change to another user only when required.

* Install required packages

        apt-get install git ruby1.9.3 memcached curl vim postfix apache2 mysql-client mysql-server build-essential apache2-threaded-dev libqrencode-dev libcurl4-gnutls-dev libmysqlclient-dev

## Prepare the RoR environment

* Use gem to install `bundler` rubygem package:

        gem install bundler

## Create a regular user to run RoR app

* We'll use the 'webapp' user and it'll be added to 'sudo' group temporarily, this way, all the required packages to run **Bitfication**, will get installed on your Ubuntu.

        adduser webapp
        adduser webapp sudo

## Become 'webapp' and get the code

* Fork project if relevant

* Clone the **Bitficaion** source code with git

        su - webapp
        git clone https://bitbucket.org/tmartinx/bitfication.git

* Or if you have a BitBucket account (and if you fork the code):

        git clone https://tmartinx@bitbucket.org/tmartinx/bitfication.git

* Get into the sources directory

        cd ~/bitfication

* Compile and install the required dependencies

        sudo bundle install

* Log-in to MySQL console and run the following commands. If you are installing a production machine you'll obviously need to pick different credentials. Update the `config/database.yml` file accordingly.

        > CREATE DATABASE bitficdevdb;
        > GRANT ALL PRIVILEGES ON bitficdevdb.* TO 'bitficdevusr'@'localhost' IDENTIFIED BY 'bitficpass';

* Run a couple of rake tasks (omit the `RAILS_ENV` option if you're setting up a development environment, Rails will grab the database configuration in the `config/database.yml` file under the right section (development, test, or production)

        RAILS_ENV=development rake db:setup

* Edit config/bitcoin.yml to be able to connect your instance to a bitcoin client, the `config/bitcoin.yml` file contents are self-explanatory, just add a production section if you're deploying on a production server.

* You're good to go! Run the rails server

        RAILS_ENV=development rails s

Your fresh instance should now be running on `http://localhost:3000/`!

# Production deployment (obsolete procedure)

Usually, Rails applications are deployed in production using nginx or Apache, I'll introduce the Apache option.

The `capistrano` tool is used to automate pretty much every deployment step. Deploying a new version is as easy as typing `cap deploy` in your local command prompt.

To use the `cap` sweetness a couple of extra steps are required : 

* You'll need to fork the project since all your deployment configuration is stored in `config/deploy.rb`, these configs are pulled directly from GitHub when deploying, so go for it, change them to suit your needs.

* Set the remote machine up by typing `cap deploy:setup`

* Log in to the remote machine and create the production configuration files in `{APP PATH}/shared/config/*.yml`, they will be used in production (you don't want your production passwords hanging around on GitHub do you ?)

* Create the remote DB

* Now you can run locally `cap deploy:migrations`, this will update the remote sources and run the migrations on the remote database

* Now you just need to install the `passenger` gem on the remote server which will install an apache module

* Create an apache virtual host and you're good to go.

You'll just need to issue a `cap deploy` locally for any subsequent deployment.

# Contributions

All are welcome, improvements, fixes and translations (the string extraction bounty has been paid).

 * The use of the `Numeric#to_f` method is big no-no, every single numeric that passes through the code should be typed as `BigDecimal`,

 * Bugfixes should include a failing test,

 * Pull requests should apply cleanly on top of `master`, rebase if necessary

# Updates

By **Bitfication** team!

 * Thiago Martins updated this README.md

# License

AGPL License. Copyright 2010-2011 David FRANCOIS
