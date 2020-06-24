FROM sharpreflections/centos6-build-gcc:gcc-4.8.5
LABEL maintainer="dennis.brendel@sharpreflections.com"

ARG gcc=gcc-4.8.5
ARG qt_major=5.9
ARG qt_minor=.9
ARG qt_string=qt-everywhere-opensource-src

ARG prefix=/opt

WORKDIR /build/

ENV PATH=$prefix/$gcc/bin:$PATH
ENV LD_LIBRARY_PATH=$prefix/$gcc/lib64:$LD_LIBRARY_PATH
ENV CC=/opt/$gcc/bin/gcc
ENV CXX=/opt/$gcc/bin/g++

RUN yum -y install centos-release-scl && \
    yum -y install python27 xz glibc-headers glibc-devel mesa-libGL-devel mesa-libEGL-devel openssl-devel \
           fontconfig-devel dbus-devel libXcomposite-devel libXcursor-devel libXi-devel libXrandr-devel \
           libXtst-devel gperf expat-devel && \
    source /opt/rh/python27/enable && \
    echo "Downlooading qt5: " && \
    curl --remote-name --location --progress-bar http://download.qt.io/official_releases/qt/${qt_major}/${qt_major}${qt_minor}/single/${qt_string}-${qt_major}${qt_minor}.tar.xz && \
    curl --remote-name --location --silent http://download.qt.io/official_releases/qt/${qt_major}/${qt_major}${qt_minor}/single/md5sums.txt && \
    sed --in-place '/.*\.zip/d' md5sums.txt && \
    echo -n "Verifying file.." && md5sum --quiet --check md5sums.txt && echo " done" && \
    echo -n "Extracting qt5.. " && tar xf ${qt_string}-${qt_major}${qt_minor}.tar.xz && echo " done" && \
    mkdir build && cd build && \
    ../${qt_string}-${qt_major}${qt_minor}/configure --prefix=${prefix}/qt-${qt_major}${qt_minor}-gcc485 \
                -opensource -confirm-license \
                -shared                      \
                -c++std c++11                \
                -platform linux-g++-64       \
                -ssl                         \
                -fontconfig                  \
                -system-freetype             \
                -qt-zlib                     \
                -qt-libjpeg                  \
                -qt-libpng                   \
                -nomake examples             \
                -nomake tests                \
                -no-sse4.1 -no-sse4.2        \
                -no-avx -no-avx2 -no-avx512  \
                -no-rpath                    \
                -no-cups                     \
                -no-iconv                    \
                -no-dbus                     \
                -no-gtk                      \
                -no-glib                     \
                -no-icu                      \
                -skip qt3d                   \
                -skip qtactiveqt             \
                -skip qtandroidextras        \
                -skip qtcanvas3d             \
                -skip qtcharts               \
                -skip qtconnectivity         \
                -skip qtdatavis3d            \
                -skip qtgamepad              \
                -skip qtgraphicaleffects     \
                -skip qtimageformats         \
                -skip qtlocation             \
                -skip qtmacextras            \
                -skip qtmultimedia           \
                -skip qtnetworkauth          \
                -skip qtpurchasing           \
                -skip qtsensors              \
                -skip qtserialbus            \
                -skip qtserialport           \
                -skip qtspeech               \
                -skip qttranslations         \
                -skip qtvirtualkeyboard      \
                -skip qtwayland              \
                -skip qtwebsockets           \
                -skip qtwinextras         && \
# Not skipping: qtbase
#               qtdeclarative
#               qtdoc
#               qtimageformats
#               qtquickcontrols  # required by qtwebengine
#               qtquickcontrols2
#               qtremoteobjects
#               qtscxml
#               qtscript
#               qtsvg
#               qttools
#               qtwebchannel     # required by qtwebengine
#               qtwebengine
#               qtwebview
#               qtx11extras
#               qtxmlpatterns
    make --jobs=$(nproc --all) && make install   && \
    yum -y history undo last && \
    yum clean all && \
    rm -rf /build/* && \
    rm -rf $prefix/$gcc

