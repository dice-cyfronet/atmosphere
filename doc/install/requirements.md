# Requirements

## Supported Operating Systems

- Ubuntu

It is still possible to install Atmosphere on other operating systems. List
presented above mention all operating systems, which was **already** used for
Atmosphere installation.

## Ruby versions

Atmosphere requires Ruby (MRI) 2.1.

# Hardware requirements

## CPU

**2 cores** is the **recommended** minimum number of cores.

## Memory

**6GB** is the **recommended** minimum memory size.

Notice: The 25 workers of Sidekiq will show up as separate processes in your process overview (such as top or htop) but they share the same RAM allocation since Sidekiq is a multithreaded application.

## Storage

The necessary hard drive space is necessary to store:

- Atmosphere codebase (30MB)
- Atmosphere dependencies - gems (1GB)
- Application logs (3GB)
- Atmosphere database. Size of the database depends how many compute sites
will be integrated and how many Appliance Types and Appliances will be
registered. For start 100MB should be enough.

## Redis and Sidekiq

Redis stores background task queue. The storage requirements for Redis are minimal,
about 10MB. Sidekiq processes the background jobs with a multithreaded process.
This process starts with the entire Rails stack (1GB+) but it can grow over time,
depending of number of Compute Sites integrated and number of HTTP endpoints, which
need to be monitored. On active server the Sidekiq process can use 2GB+ of memory.