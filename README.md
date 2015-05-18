# Atmosphere [![Build Status](https://travis-ci.org/dice-cyfronet/atmosphere.svg)](https://travis-ci.org/dice-cyfronet/atmosphere) [![Code Climate](https://codeclimate.com/github/dice-cyfronet/atmosphere/badges/gpa.svg)](https://codeclimate.com/github/dice-cyfronet/atmosphere) [![Test Coverage](https://codeclimate.com/github/dice-cyfronet/atmosphere/badges/coverage.svg)](https://codeclimate.com/github/dice-cyfronet/atmosphere) [![Dependency Status](https://gemnasium.com/dice-cyfronet/atmosphere.svg)](https://gemnasium.com/dice-cyfronet/atmosphere)

Atmosphere is a hybrid computational cloud management framework which sits atop computational cloud sites and provides a consistent interface for creation and management of cloud-based services and applications. It provides a set of APIs as well as an embeddable administrative GUI through which computational clouds can be managed. Atmosphere also provides separate tools for developers of services and for their end users.

Atmosphere introduces an abstraction above cloud-based virtual machines by referring to services as **Appliance types** and their instances (VMs) as **Appliances**:

- An **Appliance Type** represents an image of a cloud-based service, along with ancillary metadata and all other types of information required to expose the service to end users. From the end user's perspective, an Appliance Type is just a service template which can be launched (instantiated) on demand.
- An **Appliance** represents a running instance of an Appliance Type. An Appliance is always spawned in the context of a specific user account, however Appliances have a many-to-many relation with virtual machines. For services which are declared as "shared", a single Virtual Machine may map to many Appliances, thus enabling many users to share a single VM even though each user sees their own "virtual service". For services which are declared as "scalable", the opposite happens - a user may launch an Appliance which Atmosphere will then link to many Virtual Machines, redirecting incoming requests to specific VMs in accordance with an internal optimization strategy.

The above abstraction enables the platform to conserve hardware resources while also providing scale-out capabilities for more demanding applications.

Atmosphere also resolves a host of other issues involved in operating computational clouds. It is capable of automatically creating redirections to services exposed by Appliances in private IP spaces, through the use of two types of proxies: a NAT-based port proxy for arbitrary interfaces, and a Nginx-based HTTP proxy for web interfaces (SOAP, REST, web applications etc.) A billing system is provided to keep track of financial resource usage and a set of monitoring workers are in place to validate the accessibility of service interfaces. A template migration mechanism is also provided whereby Appliance Types stored on one participating cloud site may be automatically propagated to other cloud sites, with on-the-fly image conversion where necessary.

The principal use of Atmosphere is in aggregating multiple computational cloud sites into a coherent infrastructure which the users perceive as a single, shared resource space.

## Requirements

### Supported Operating Systems

- Ubuntu 12.04
- Ubuntu 14.04

It may be possible to install Atmosphere on other operating systems. The above list only includes
operating systems which have **already** been used for Atmosphere deployment in production mode. What is more,
some commands used in the installation manual are Debian-specific (e.g. `apt-get`). If your OS uses a different
package management system, you will need to modify these commands appropriately (e.g. by calling `yum` if you are using CentOS).

### Ruby versions

Atmosphere requires Ruby (MRI) >= 2.1.

## Hardware requirements

### CPU

**2 cores** is the **recommended** minimum number of cores.

### Memory

**6GB** is the **recommended** minimum memory size.

Note: The 25 workers of Sidekiq will show up as separate processes in your process overview (such as top or htop) but they share the same RAM allocation since Sidekiq is a multithreaded application.

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
gem 'atmosphere', github: 'dice-cyfronet/atmosphere', branch: 'master'
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

# apply new migrations
rake db:migrate
```

## Using atmosphere factories

Atmosphere factories are exposed into dependent projects in `test` environment. To use them you need to define following dependency in your `Gemfile`:

```ruby
gem 'ffaker', '~>2.0.0'
```

## Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new pull request
6. When feature is ready add "ready for review" label and mention atmosphere
   development team (e.g. "/cc @dice-cyfronet/atmo-dev-team please take a look")
