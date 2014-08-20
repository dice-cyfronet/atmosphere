# Requirements

## Supported Operating Systems

- Ubuntu 12.04
- Ubuntu 14.04

It may be possible to install Atmosphere on other operating systems. The above list only includes
operating systems, which have **already** been used for Atmosphere deployment in production mode. What is more,
some commands used in the installation manual are Debian-specific (e.g. `apt-get`). If your OS uses a different
package management system, you will need to modify these commands appropriately (e.g. by calling `yum` if you are using CentOS).

## Ruby versions

Atmosphere requires Ruby (MRI) 2.1.

# Hardware requirements

## CPU

**2 cores** is the **recommended** minimum number of cores.

## Memory

**6GB** is the **recommended** minimum memory size.

Notice: The 25 workers of Sidekiq will show up as separate processes in your process overview (such as top or htop) but they share the same RAM allocation since Sidekiq is a multithreaded application.

## Storage

The following components must reside in your attached storage:

- Atmosphere codebase (30MB)
- Atmosphere dependencies - gems (1GB)
- Application logs (3GB)
- Atmosphere database (Note: the volume of the database depends on how many compute sites
will be integrated and how many Appliance Types and Appliances will be
registered. 100MB should be enough for standard deployments.)

## Redis and Sidekiq

Redis manages the background task queue. Storage requirements for Redis are minimal (on the order of 10 MB).
Sidekiq processes background jobs using a multithreaded process. This process starts along with the entire Rails stack (1GB+) but it may grow over time,
depending of the number of compute sites integrated with atmosphere and the number of instance-bound HTTP endpoints which
need to be monitored. On a heavily loaded server the Sidekiq process may allocate 2GB+ of memory.