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

Interactive demo
----------------

    git clone $BENCHMARK_GIT_REPO_URL $BENCHMARK_GIT_REPO_PATH
    ./benchmarks.py configure_bazel --cache

    cd $BENCHMARK_GIT_REPO_PATH
    cloc .

    # Let's build some code now
    git checkout $BENCHMARK_GIT_REV_OLD

    # The cache is empty
    rm -rf /src/cacher_root/*

    bazel build //drake/examples:simple_continuous_time_system
    # This took x seconds
    # A no-op build is very fast:
    bazel build //drake/examples:simple_continuous_time_system

    # We filled up the cache:
    du -sh /src/cacher_root

    # Let's checkout a different revision
    git checkout $BENCHMARK_GIT_REV_NEW
    # There's quite a difference between the two
    git diff $BENCHMARK_GIT_REV_OLD $BENCHMARK_GIT_REV_NEW | wc -l

    # Build this new revision
    bazel build //drake/examples:simple_continuous_time_system

    # Let's check the cache again
    du -sh /src/cacher_root

    # Go back to the first
    git checkout $BENCHMARK_GIT_REV_OLD

    # Build again
    bazel build //drake/examples:simple_continuous_time_system

    # Let's spin up a new instance and make sure it can use the cache
    exit

    docker-compose run builder bash

    git clone $BENCHMARK_GIT_REPO_URL $BENCHMARK_GIT_REPO_PATH
    ./benchmarks.py configure_bazel --cache

    git checkout $BENCHMARK_GIT_REV_OLD

    # The cache is still there:
    du -sh /src/cacher_root

    bazel build //drake/examples:simple_continuous_time_system
