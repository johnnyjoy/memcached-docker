# Memcached Container

Memcached is a high performance multithreaded event-based key/value cache
store intended to be used in a distributed system.

See: https://memcached.org/about

## Quick Start

$ docker run -p11211:11211 -e MC_MEM=128 -d --name tigersmile/memcached:latest

## Overview

This container holds only memcached compiled from sources, statically linked,
and then stripped. Other than the few other files required this is all that
is in the container, making it as small as it can be. On the amd64 architature
this would be 393kb container size(docker ps -s).

Since there are no shell included in the container memcached had to be modified
to pass command line options as environment variables. Each instance of the
image can be configured differently.

## Settings

Settings are passed to memcached using environment variables.

MC_MAX=&lt;num&gt;

Use &lt;num&gt; MB memory max to use for object storage; the default is 64 megabytes.

MC_CONNECTIONS=&lt;num&gt;

Use &lt;num&gt; max simultaneous connections; the default is 1024.

MC_TREADS=&lt;num&gt;

Number of threads to use to process incoming requests. This option is only
meaningful if memcached was compiled with thread support enabled. It is
typically not useful to set this higher than the number of CPU cores on the
memcached server. The default is 4.

MC_PORT=&lt;num&gt;

Listen on TCP port &lt;num&gt;, the default is port 11211.

MC_TLS=true

Enables TLS support. Requires MC_TLS_CERT and MC_TLS_KEY.

MC_TLS_CERT=&lt;filename&gt;

Certificate file in PEM format. Required if MC_TLS is true.

MC_TLS_KEY=&lt;filename&gt;

Key file in PEM format. Required if MC_TLS is true.

## Bug reports

See https://notabug.org/jjb/memcached/issues

## Website

* https://notabug.org/jjb/memcached 
