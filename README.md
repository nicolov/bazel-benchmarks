Bazel build benchmarks
======================

[Bazel](http://bazel.build) is Google's open source build system. This repo is
a companion to my [blog post]() and contains the configuration and scripts that
I used for benchmarks.

The `cacher` _docker compose` service is a simple instance of nginx + WebDAV to
serve as a remote cache. The `builder` does the actual C++ builds with Bazel and
clang 3.9.

Set-up
------

You'll need _docker_ and _docker-compose_ installed. Then:

    docker-compose build && docker-compose up

will build the images and start the cache server. Then, get a builder shell:

    docker-compose run builder bash
