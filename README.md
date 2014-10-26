# Atmosphere [![Build Status](https://travis-ci.org/dice-cyfronet/atmosphere.svg)](https://travis-ci.org/dice-cyfronet/atmosphere) [![Code Climate](https://codeclimate.com/github/dice-cyfronet/atmosphere/badges/gpa.svg)](https://codeclimate.com/github/dice-cyfronet/atmosphere) [![Test Coverage](https://codeclimate.com/github/dice-cyfronet/atmosphere/badges/coverage.svg)](https://codeclimate.com/github/dice-cyfronet/atmosphere) [![Dependency Status](https://gemnasium.com/dice-cyfronet/atmosphere.svg)](https://gemnasium.com/dice-cyfronet/atmosphere)



## Requirements

+ Ubuntu
+ ruby 2.1+
+ git 1.7.10+
+ redis 2.0+
+ PostgreSQL

More details are in the [requirements doc](doc/install/requirements.md).

## Installation

Please see the [installation manual](doc/install/installation.md).

## New version

We are using continous delivery methodology. All features are implemented in
branches, when feature is ready and tested then it is merged into master. As a
conclusion it should be safe to push master changes into your production
environment.

```
git pull origin master
git push production master
```

As a conclusion new version is deployed, all required gems are installed,
database migrations are triggered, new upstart starting scripts are generated
and application is restarted (frontend is restarted in such a way to not drop
any user request).
