# Overview

The Atmosphere installation consists of setting up the following components:

1. Packages / Dependencies
1. Ruby
1. System User
1. Database
1. Upstart
1. Atmosphere
1. Nginx
1. Atmosphere administrator
1. Logrotate
1. IPWrangler
1. Redirus worker

## 1. Packages / Dependencies

Install the required packages (needed to compile Ruby and native extensions to
Ruby gems):

```
sudo apt-get update

sudo apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev openssh-server redis-server curl wget checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev logrotate
```

Make sure you have the right version of Git installed

```
# Install Git
sudo apt-get install -y git-core

# Make sure Git is version 1.7.10 or higher, for example 1.7.12 or 2.0.0
git --version
```

Is the system packaged Git too old? Remove it and compile from source.

```
# Remove packaged Git
sudo apt-get remove git-core

# Install dependencies
sudo apt-get install -y libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev build-essential

# Download and compile from source
cd /tmp
curl --progress https://www.kernel.org/pub/software/scm/git/git-2.0.0.tar.gz | tar xz
cd git-2.0.0/
make prefix=/usr/local all

# Install
sudo make install
```

Note: In order to receive mail notifications, make sure to install a mail server.

```
sudo apt-get install -y postfix
```

## 2. Ruby

You can use ruby installed by ruby version managers such as (RVM)[http://rvm.io/]
or (rbenv)[https://github.com/sstephenson/rbenv] or install it glabaly from the sources. Bellow global ruby installation will be presented.

Remove the old Ruby 1.8 if present

```
sudo apt-get remove ruby1.8
```

Download Ruby and compile it:

```
mkdir /tmp/ruby && cd /tmp/ruby
curl --progress ftp://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz | tar xz
cd ruby-2.1.2
./configure --disable-install-rdoc
make
sudo make install
```

Install the Bundler and Foreman Gems:

```
sudo gem install bundler --no-ri --no-rdoc
sudo gem install foreman --no-ri --no-rdoc
```

## 3. System User

Create a `atmosphere` user for Atmosphere:

```
sudo adduser --gecos 'Atmosphere' atmosphere
```

## 4. Database

Install PostgreSQL database.

```
# Install the database packages
sudo apt-get install -y postgresql-9.3 postgresql-client libpq-dev

# Login to PostgreSQL
sudo -u postgres psql -d template1

# Create a user for Atmosphere.
template1=# CREATE USER atmosphere CREATEDB;

# Create the Atmosphere production database & grant all privileges on database
template1=# CREATE DATABASE atmosphere_production OWNER atmosphere;

# Quit the database session
template1=# \q

# Try connecting to the new database with the new user
sudo -u atmosphere -H psql -d atmosphere_production
```

## 5. Upstart

Upstart is used to manage Atmosphere and Redirus worker lifecycle
(`start`/`stop`/`restart`).

Replace `/etc/dbus-1/system.d/Upstart.conf` with content presented bellow
to allow any user to invoke all of upstarts methods:

```
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE busconfig PUBLIC
  "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
  "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">

<busconfig>
  <!-- Only the root user can own the Upstart name -->
  <policy user="root">
    <allow own="com.ubuntu.Upstart" />
  </policy>

  <!-- Allow any user to invoke all of the methods on Upstart, its jobs
       or their instances, and to get and set properties - since Upstart
       isolates commands by user. -->
  <policy context="default">
    <allow send_destination="com.ubuntu.Upstart"
       send_interface="org.freedesktop.DBus.Introspectable" />
    <allow send_destination="com.ubuntu.Upstart"
       send_interface="org.freedesktop.DBus.Properties" />
    <allow send_destination="com.ubuntu.Upstart"
       send_interface="com.ubuntu.Upstart0_6" />
    <allow send_destination="com.ubuntu.Upstart"
       send_interface="com.ubuntu.Upstart0_6.Job" />
    <allow send_destination="com.ubuntu.Upstart"
       send_interface="com.ubuntu.Upstart0_6.Instance" />
  </policy>
</busconfig>
```

Add to `${HOME}/.bash_profile` (where `${HOME}` is the home directory of user used to run `upstart`):

```
if [ ! -f /var/run/user/$(id -u)/upstart/sessions/*.session ]
then
    /sbin/init --user --confdir ${HOME}/.init &
fi

if [ -f /var/run/user/$(id -u)/upstart/sessions/*.session ]
then
   export $(cat /var/run/user/$(id -u)/upstart/sessions/*.session)
fi
```

More information in (Upstart Cookbook)[http://upstart.ubuntu.com/cookbook/] in sections:

* (user job)[http://upstart.ubuntu.com/cookbook/#user-job]
* (enabling user job)[http://upstart.ubuntu.com/cookbook/#enabling]
* (session job)[http://upstart.ubuntu.com/cookbook/#session-job]
* (session init)[http://upstart.ubuntu.com/cookbook/#session-init]

## 6. Atmosphere

We use Git `hooks` to deploy new version of atmosphere.

Prepare clean git repository:

```
# We'll install Atmosphere into home directory of the user "atmosphere"
cd /home/atmosphere

# Create Atmosphere home directory
sudo -u atmosphere -H mkdir current

# Init empty git repository...
sudo -u atmosphere -H git init /home/atmosphere/current

# ...and allow to push to this repository
cd /home/atmosphere/current
sudo -u atmosphere -H git config receive.denyCurrentBranch ignore
```

Install post hook which will be triggered every time new code is pushed into the
repository

```
# Download post-receive hook...
sudo -u atmosphere -H wget --no-check-certificate https://gitlab.dev.cyfronet.pl/atmosphere/air/raw/master/lib/support/git/post-receive -O /home/atmosphere/current/.git/hooks/post-receive

# ...and make it executable
sudo -u atmosphere -H chmod +x /home/atmosphere/current/.git/hooks/*
```

Install modified templates for foreman upstart script generation. If you are
using one of ruby version management tool than please uncomment apropriate
line in `/home/atmosphere/upstart-templates/process.conf.erb`

```
# Create dir for upstart templates
sudo -u atmosphere -H mkdir /home/atmosphere/upstart-templates

# Download templates
sudo -u atmosphere -H wget --no-check-certificate https://gitlab.dev.cyfronet.pl/atmosphere/air/raw/master/lib/support/git/upstart-templates/master.conf.erb -O /home/atmosphere/upstart-templates/master.conf.erb

sudo -u atmosphere -H wget --no-check-certificate https://gitlab.dev.cyfronet.pl/atmosphere/air/raw/master/lib/support/git/upstart-templates/process.conf.erb -O /home/atmosphere/upstart-templates/process.conf.erb

sudo -u atmosphere -H wget --no-check-certificate https://gitlab.dev.cyfronet.pl/atmosphere/air/raw/master/lib/support/git/upstart-templates/process_master.conf.erb -O /home/atmosphere/upstart-templates/process_master.conf.erb

# Create directory for generated upstart scripts
sudo -u atmosphere -H mkdir /home/atmosphere/.init
```

Create Atmosphere configuration files

```
sudo -u atmosphere -H mkdir /home/atmosphere/current/config
sudo -u atmosphere -H mkdir /home/atmosphere/current/config/initializers

# Download required configuration files
sudo -u atmosphere -H wget --no-check-certificate https://gitlab.dev.cyfronet.pl/atmosphere/air/raw/master/config/database.yml.postgresql -O /home/atmosphere/current/config/database.yml

sudo -u atmosphere -H wget --no-check-certificate https://gitlab.dev.cyfronet.pl/atmosphere/air/raw/master/config/air.yml.example -O /home/atmosphere/current/config/air.yml

sudo -u atmosphere -H wget --no-check-certificate https://gitlab.dev.cyfronet.pl/atmosphere/air/raw/master/config/puma.rb.example -O /home/atmosphere/current/config/puma.rb

sudo -u atmosphere -H wget --no-check-certificate https://gitlab.dev.cyfronet.pl/atmosphere/air/raw/master/config/initializers/action_mailer.rb.example -O /home/atmosphere/current/config/initializers/action_mailer.rb

# Customize configuration files
sudo -u atmosphere -H editor /home/atmosphere/current/config/database.yml
sudo -u atmosphere -H editor /home/atmosphere/current/config/air.yml
sudo -u atmosphere -H editor /home/atmosphere/current/config/puma.rb
sudo -u atmosphere -H editor /home/atmosphere/current/config/initializers/action_mailer.rb
```

Clone atmosphere code locally (on e.g. your laptop)

```
git clone https://gitlab.dev.cyfronet.pl/atmosphere/air.git
```

Generate locally two random secrets

```
cd air
rake secret
rake secret
```
Set generated secrets as env variables on your server

```
# Open bash profile...
sudo -u atmosphere -H editor /home/atmosphere/.bash_profile

# ...and add two secrets
export SECRET_KEY_BASE=first_generated_secret
export DEVISE_SECRET_KEY_BASE=second_generated_secret
```

Add Atmosphere remote into your local Atmosphere copy

```
cd cloned_atmosphere_path
git remote add production atmosphere@production.server.ip:current
```

Push atmosphere code into production

```
git push production master
```

As a conclusion code from `master` branch will be pushed into remote server and
`post-receive` hook will be invoked. It will:
- updates remote code into required version
- installs all required dependencies (gems)
- triggers database migration
- regenerates upstart scripts
- restart application

## Nginx

```
# Install nginx
sudo apt-get install -y nginx-light

# Download Atmosphere nginx configuration file...
sudo curl --progress https://gitlab.dev.cyfronet.pl/atmosphere/air/raw/master/lib/support/nginx/atmosphere > /etc/nginx/sites-available/atmosphere

# ...enable it...
sudo ln -s /etc/nginx/sites-available /etc/nginx/sites-enabled

# ...and restart nginx
sudo service nginx restart
```

As a conclusion Atmosphere should be up and running on defined URL.

## 7. Atmosphere administrator

```
cd /home/atmosphere/current
sudo -u atmosphere -H rake db:seed
```

## 8. Logrotate

```
sudo cp /home/atmosphere/current/lib/support/logrotate/atmosphere /etc/logrotate.d/atmosphere
```

If needed create additional logrotate configuration for Redirus worker and IPWrangler.

## 9. IPWrangler

Latest version of IPWrangler is available at (gitlab/atmosphere/ipt_wr)[https://gitlab.dev.cyfronet.pl/atmosphere/ipt_wr/tree/ps-master/].

Information about installation are available at (gitlab/atmosphere/ipt_wr/README.md)[https://gitlab.dev.cyfronet.pl/atmosphere/ipt_wr/blob/ps-master/README.md].

## 10. Redirus worker

Installation procedure can be found (here)[https://github.com/dice-cyfronet/redirus-worker/blob/master/README.md]
