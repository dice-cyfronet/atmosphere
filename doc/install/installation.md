# Overview

Atmosphere installation consists of setting up the following components:

1. Packages / Dependencies
2. Ruby interpreter
3. System user account
4. Database configuration
5. Upstart scripts
6. Atmosphere application
7. Nginx web server
8. Atmosphere administrator account
9. Logrotate
10. IPWrangler (for TCP/UDP redirections)
11. Redirus worker (for smart HTTP(s) redirections)

## 1. Packages / Dependencies

Install the required packages (reqired to compile Ruby and native extensions to Ruby gems):

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

If the Git version installed by the system is too old, remove it and compile from source.

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

Note: In order to receive e-mail notifications, make sure to install a mail server.

```
sudo apt-get install -y postfix
```

## 2. Ruby

You can use ruby installed by ruby version managers such as [RVM](http://rvm.io/)
or [rbenv](https://github.com/sstephenson/rbenv), or install it globally from sources. The following manual presents global installation.

Remove old Ruby 1.8, if present:

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

Create an `atmosphere` user for Atmosphere:

```
sudo adduser --gecos 'Atmosphere' atmosphere
```

## 4. Database setup

Install PostgreSQL database.

```
# Install the database packages
sudo apt-get install -y postgresql-9.3 postgresql-client libpq-dev

# Log in to PostgreSQL
sudo -u postgres psql -d template1

# Create a user for Atmosphere
template1=# CREATE USER atmosphere CREATEDB;

# Create the Atmosphere production database & grant all privileges to user atmosphere
template1=# CREATE DATABASE atmosphere_production OWNER atmosphere;

# Quit the database session
template1=# \q

# Try connecting to the new database with the new user
sudo -u atmosphere -H psql -d atmosphere_production
```

## 5. Upstart

Upstart is used to manage the Atmosphere and Redirus worker lifecycle
(`start`/`stop`/`restart`).

Replace `/etc/dbus-1/system.d/Upstart.conf` with the content presented below
to allow any user to invoke all upstart methods:

```xml
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

Add the following to `${HOME}/.bash_profile` (where `${HOME}` is the home directory of user who is to run `upstart`):

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

Change the owner of this file:

```
sudo chown atmosphere:atmosphere /home/atmosphere/.bash_profile
```


More information can be found in the (Upstart Cookbook)[http://upstart.ubuntu.com/cookbook/], particularly in the following sections:

* (user job)[http://upstart.ubuntu.com/cookbook/#user-job]
* (enabling user job)[http://upstart.ubuntu.com/cookbook/#enabling]
* (session job)[http://upstart.ubuntu.com/cookbook/#session-job]
* (session init)[http://upstart.ubuntu.com/cookbook/#session-init]

## 6. Atmosphere

We use Git `hooks` to automatically deploy new releases of atmosphere.

Prepare a clean git repository:

```
# We'll install Atmosphere into the home directory of the user "atmosphere"
cd /home/atmosphere

# Create the Atmosphere home directory
sudo -u atmosphere -H mkdir current

# Init empty git repository...
sudo -u atmosphere -H git init /home/atmosphere/current

# ...and enable pushing to this repository.
cd /home/atmosphere/current
sudo -u atmosphere -H git config receive.denyCurrentBranch ignore
```

Install the post hook which will be triggered every time new code is pushed into the
repository

```
# Download post-receive hook...
sudo -u atmosphere -H wget --no-check-certificate https://gitlab.dev.cyfronet.pl/atmosphere/air/raw/master/lib/support/git/post-receive -O /home/atmosphere/current/.git/hooks/post-receive

# ...and make it executable
sudo -u atmosphere -H chmod +x /home/atmosphere/current/.git/hooks/*
```

Install modified templates for foreman upstart script generation. If you are
using a ruby version management tool than please uncomment the appropriate
line in `/home/atmosphere/upstart-templates/process.conf.erb`

```
# Create directory for upstart templates
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

Clone atmosphere code locally (e.g. on your laptop):

```
GIT_SSL_NO_VERIFY=1 git clone https://gitlab.dev.cyfronet.pl/atmosphere/air.git
```

Generate two random secrets locally:

```
cd air
rake secret
rake secret
```
Expose generated secrets as environmental variables on your server

```
# Open bash profile...
sudo -u atmosphere -H editor /home/atmosphere/.bash_profile

# ...and add two secrets
export SECRET_KEY_BASE=<first_generated_secret>
export DEVISE_SECRET_KEY_BASE=<second_generated_secret>
```

Install nodejs for compiling java script files

```
sudo apt-get install -y nodejs
```

Add Atmosphere remote to your local Atmosphere copy

```
cd cloned_atmosphere_path
git remote add production atmosphere@production.server.ip:current
```

Push atmosphere code into production

```
git push production master
```

As a result, code from the `master` branch will be pushed into the remote server and
the `post-receive` hook will be invoked. It will:
- update remote code to requested version
- install all required dependencies (gems)
- perform database migration
- regenerate upstart scripts
- restart the application.

## Nginx

```
# Install nginx
sudo apt-get install -y nginx-light

# Download Atmosphere nginx configuration file
sudo wget --no-check-certificate https://gitlab.dev.cyfronet.pl/atmosphere/air/raw/master/lib/support/nginx/atmosphere -O /etc/nginx/sites-available/atmosphere

# customize nginx configuration file
sudo editor /etc/nginx/sites-available/atmosphere

# ...enable it...
sudo ln -s /etc/nginx/sites-available/atmosphere /etc/nginx/sites-enabled/atmosphere

# ...and restart nginx
sudo service nginx restart
```

As a conclusion Atmosphere should be up and running under the selected URL.

## 7. Atmosphere administrator

```
sudo su - atmosphere
cd /home/atmosphere/current
bundle exec rake db:seed
exit
```

## 8. Logrotate

```
sudo cp /home/atmosphere/current/lib/support/logrotate/atmosphere /etc/logrotate.d/atmosphere
```

If needed, create additional logrotate configurations for Redirus workers and IPWrangler.

## 9. IPWrangler

Documentation is available [here](https://gitlab.dev.cyfronet.pl/atmosphere/ipt_wr/blob/master/README.md).

## 10. Redirus worker

Installation documentation is available [here](https://github.com/dice-cyfronet/redirus-worker/blob/master/README.md).
