FROM sharpreflections/centos6-build-gcc
LABEL maintainer="dennis.brendel@sharpreflections.com"

ARG gcc=gcc-5.5.0

ARG prefix=/opt

WORKDIR /build/

ENV PATH=$prefix/$gcc/bin:$PATH
ENV LD_LIBRARY_PATH=$prefix/$gcc/lib64:$LD_LIBRARY_PATH
ENV CC=/opt/$gcc/bin/gcc
ENV CXX=/opt/$gcc/bin/g++

RUN yum -y install xz glibc-headers glibc-devel mesa-libGL-devel mesa-libEGL-devel && \
    echo "Downlooading qt5: " && \
    curl --remote-name --location --progress-bar http://download.qt.io/official_releases/qt/5.14/5.14.1/single/qt-everywhere-src-5.14.1.tar.xz && \
    curl --remote-name --location --silent http://download.qt.io/official_releases/qt/5.14/5.14.1/single/md5sums.txt && \
    sed --in-place '/.*\.zip/d' md5sums.txt && \
    echo -n "Verifying file.." && md5sum --quiet --check md5sums.txt && echo " done" && \
    echo "Extracting qt5.. " && tar xf qt-everywhere-src-5.14.1.tar.xz && echo " done" && \
    mkdir build && cd build && \
    ../qt-everywhere-src-5.14.1/configure --prefix=/opt/qt-5.14.1-gcc   \
                -opensource -confirm-license \
                -shared                      \
                -c++std c++11                \
                -platform linux-g++-64       \
                -qt-zlib                     \
                -qt-libjpeg                  \
                -qt-libpng                   \
                -nomake examples             \
                -no-rpath                    \
                -no-cups                     \
                -no-iconv                    \
                -no-dbus                     \
                -no-gtk                      \
                -no-glib                  && \
    gmake --jobs=$(nproc --all) && gmake install   && \
    yum -y history undo last && \
    yum clean all && \
    cd /build && rm -rf *

