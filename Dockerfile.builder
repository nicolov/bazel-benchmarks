FROM ubuntu:xenial

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        wget \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list
RUN curl https://bazel.build/bazel-release.pub.gpg | apt-key add -

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bazel \
    && rm -rf /var/lib/apt/lists/*

# drake
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        lsb-core \
        software-properties-common \
        wget \
    && wget -q -O - http://llvm.org/apt/llvm-snapshot.gpg.key | apt-key add - \
    && add-apt-repository -y "deb http://apt.llvm.org/trusty/ llvm-toolchain-trusty-3.9 main" \
    && add-apt-repository ppa:webupd8team/java \
    && add-apt-repository ppa:george-edison55/cmake-3.x \
    && apt-get update

RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections

RUN apt-get install -y --no-install-recommends \
        clang-3.9 \
        gfortran \
        cmake \
        oracle-java8-installer \
        autoconf automake bison doxygen freeglut3-dev git graphviz \
        libboost-dev libboost-system-dev libgtk2.0-dev libhtml-form-perl \
        libjpeg-dev libmpfr-dev libpng-dev libterm-readkey-perl libtinyxml-dev \
        libtool libvtk5-dev libwww-perl make ninja-build \
        patchutils perl pkg-config \
        python-bs4 python-dev python-gtk2 python-html5lib python-numpy \
        python-pip python-sphinx python-yaml unzip valgrind \
    && rm -rf /var/lib/apt/lists/*

RUN bazel version

WORKDIR /src

# Python dependencies for test scripts
COPY requirements.txt /src/
RUN pip install --upgrade pip \
    && pip install setuptools \
    && pip install -r requirements.txt

CMD bash