FROM ubuntu:xenial

ENV BAZEL_VERSION 0.5.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        wget \
        git \
    && rm -rf /var/lib/apt/lists/*

# JDK for Bazel
RUN apt-get update \
    && apt-get install -y software-properties-common \
    && apt-add-repository ppa:webupd8team/java --yes \
    && apt-get update \
    && echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections \
    && apt-get install -y --no-install-recommends \
        oracle-java8-installer \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Bazel
RUN cd /tmp \
    && curl -L -o install-bazel.sh https://github.com/bazelbuild/bazel/releases/download/0.5.2/bazel-$BAZEL_VERSION-without-jdk-installer-linux-x86_64.sh \
    && bash install-bazel.sh \
    && /usr/local/bin/bazel --batch version \
    && rm -rf install-bazel.sh

# drake
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        software-properties-common \
        lsb-core \
    && wget -q -O - http://llvm.org/apt/llvm-snapshot.gpg.key | apt-key add - \
    && add-apt-repository -y "deb http://apt.llvm.org/trusty/ llvm-toolchain-trusty-3.9 main" \
    && add-apt-repository ppa:george-edison55/cmake-3.x \
    && apt-get update


RUN apt-get install -y --no-install-recommends \
        clang-3.9 gfortran cmake \
        autoconf automake bison doxygen freeglut3-dev git graphviz \
        libboost-dev libboost-system-dev libgtk2.0-dev libhtml-form-perl \
        libjpeg-dev libmpfr-dev libpng-dev libterm-readkey-perl libtinyxml-dev \
        libtool libvtk5-dev libwww-perl make ninja-build \
        patchutils perl pkg-config \
        python-bs4 python-dev python-gtk2 python-html5lib python-numpy \
        python-pip python-sphinx python-yaml unzip valgrind zip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L -o /usr/local/bin/cloc \
        https://github.com/AlDanial/cloc/releases/download/v1.72/cloc-1.72.pl \
    && chmod +x /usr/local/bin/cloc

WORKDIR /src

# Python dependencies for test scripts
COPY requirements.txt /src/
RUN pip install --upgrade pip \
    && pip install setuptools \
    && pip install -r requirements.txt

ENV BENCHMARK_GIT_REPO_PATH /code
ENV BENCHMARK_GIT_REPO_URL https://github.com/RobotLocomotion/drake.git
# Two random revisions of the code, ~ 1 week apart
ENV BENCHMARK_GIT_REV_OLD 290724e
ENV BENCHMARK_GIT_REV_NEW 60b5ed9

# ENV BENCHMARK_BUILD_TARGET "//..." # ~30m
ENV BENCHMARK_BUILD_TARGET "//drake/examples:simple_continuous_time_system"  # ~30s
# ENV BENCHMARK_BUILD_TARGET "//drake/examples/QPInverseDynamicsForHumanoids/system:valkyrie_controller"  # ~5m

CMD bash
