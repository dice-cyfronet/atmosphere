# Atmosphere [![Build Status](https://travis-ci.org/dice-cyfronet/atmosphere.svg)](https://travis-ci.org/dice-cyfronet/atmosphere) [![Code Climate](https://codeclimate.com/github/dice-cyfronet/atmosphere/badges/gpa.svg)](https://codeclimate.com/github/dice-cyfronet/atmosphere) [![Test Coverage](https://codeclimate.com/github/dice-cyfronet/atmosphere/badges/coverage.svg)](https://codeclimate.com/github/dice-cyfronet/atmosphere) [![Dependency Status](https://gemnasium.com/dice-cyfronet/atmosphere.svg)](https://gemnasium.com/dice-cyfronet/atmosphere)

TODO: PN general atmosphere introduction with appliance type, appliance explanation.


## Requirements

### Supported Operating Systems

- Ubuntu 12.04
- Ubuntu 14.04

It may be possible to install Atmosphere on other operating systems. The above list only includes
operating systems, which have **already** been used for Atmosphere deployment in production mode. What is more,
some commands used in the installation manual are Debian-specific (e.g. `apt-get`). If your OS uses a different
package management system, you will need to modify these commands appropriately (e.g. by calling `yum` if you are using CentOS).

### Ruby versions

Atmosphere requires Ruby (MRI) >= 2.1.

## Hardware requirements

### CPU

**2 cores** is the **recommended** minimum number of cores.

### Memory

**6GB** is the **recommended** minimum memory size.

Notice: The 25 workers of Sidekiq will show up as separate processes in your process overview (such as top or htop) but they share the same RAM allocation since Sidekiq is a multithreaded application.

### Storage

The following components must reside in your attached storage:

- Atmosphere codebase (30MB)
- Atmosphere dependencies - gems (1GB)
- Application logs (3GB)
- Atmosphere database (Note: the volume of the database depends on how many compute sites
will be integrated and how many Appliance Types and Appliances will be
registered. 100MB should be enough for standard deployments.)

### Redis and Sidekiq

Redis manages the background task queue. Storage requirements for Redis are minimal (on the order of 10 MB).
Sidekiq processes background jobs using a multithreaded process. This process starts along with the entire Rails stack (1GB+) but it may grow over time,
depending of the number of compute sites integrated with atmosphere and the number of instance-bound HTTP endpoints which
need to be monitored. On a heavily loaded server the Sidekiq process may allocate 2GB+ of memory.

## Getting started

Atmosphere works with Rails 4.1 onwards. You can add it to your Gemfile with:

```
gem 'devise', github: 'dice-cyfronet/atmosphere', branch: 'master'
```

Run the bundle command to install it.

After you install Atmosphere and add it to your Gemfile, you need to run the generator:

```
rails generate atmosphere:install
```

The generator will install an initializer which describes ALL of Atmosphere's configuration options. It is imperative that you take a look at it. When you are done, you are can start your rails apps with Atmosphere mounted.

If you need to extend Atmosphere then you can install extensions by executing:

```
rails generate atmosphere:extensions
```

We use concerns to add additional, deployment specific logic into atmosphere.
If you need additional extension points please create new
[issue](https://github.com/dice-cyfronet/atmosphere/issues/new).

## New version

We are using continous delivery methodology. All features are implemented in
branches, when feature is ready and tested then it is merged into master. As a
conclusion it should be safe to use master in your project.

To upgrade to latest master run following commands:

```
# update atmosphere gem
bundle update atmosphere

# install new migrations
rake atmosphere:install:migrations
```

## Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new pull request