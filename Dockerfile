FROM sharpreflections/centos6-build-gcc
LABEL maintainer="dennis.brendel@sharpreflections.com"

ARG gcc=gcc-8.3.1
ARG qt_major=5.12
ARG qt_minor=.0
ARG qt_version=${qt_major}${qt_minor}
ARG qt_string=qt-everywhere-src

ARG qt_donor_major=5.9
ARG qt_donor_minor=.9
ARG qt_donor=${qt_donor_major}${qt_donor_minor}
ARG qt_donor_string=qtwebengine-opensource-src

ARG prefix=/opt
ARG suffix=gcc831

WORKDIR /build/
COPY versiontag5120.patch /build/
COPY qtwebengine599.patch /build/
COPY qtwebengine_rpath.patch /build/
COPY gcc_rpath.patch /build/
COPY qt_no_append_rpath.path /build/

ENV CC=gcc
ENV CXX=g++

RUN yum -y install centos-release-scl && \
    yum -y install python27 xz glibc-headers glibc-devel mesa-libGL-devel mesa-libEGL-devel openssl-devel \
               fontconfig-devel dbus-devel libXcomposite-devel libXcursor-devel libXi-devel libXrandr-devel \
               libXtst-devel gperf expat-devel xkeyboard-config nss-devel devtoolset-8 && \
    source /opt/rh/python27/enable && \
    source /opt/rh/devtoolset-8/enable && \

    echo "Downloading Qt5 ${qt_version}:" && \
      curl --remote-name --location --progress-bar http://download.qt.io/official_releases/qt/${qt_major}/${qt_version}/single/${qt_string}-${qt_version}.tar.xz && \
      curl --remote-name --location --silent http://download.qt.io/official_releases/qt/${qt_major}/${qt_version}/single/md5sums.txt && \

    echo -n "Verifying file.." && \
      sed --in-place '/.*\.zip/d' md5sums.txt && \
      md5sum --quiet --check md5sums.txt && \
    echo " done" && \

    rm md5sums.txt && \
    echo "Downloading Qt5 WebEngine ${qt_donor}:" && \
      curl --remote-name --location --progress-bar http://download.qt.io/official_releases/qt/${qt_donor_major}/${qt_donor}/submodules/${qt_donor_string}-${qt_donor}.tar.xz && \
      curl --remote-name --location --silent http://download.qt.io/official_releases/qt/${qt_donor_major}/${qt_donor}/submodules/md5sums.txt && \

    echo -n "Verifying file.." && \
      grep qtwebengine md5sums.txt > md5sums.txt.new && \
      mv md5sums.txt.new md5sums.txt && \
      sed --in-place '/.*\.zip/d' md5sums.txt && \
      md5sum --quiet --check md5sums.txt && \
    echo " done" && \

    echo -n "Extracting Qt5 ${qt_version}" && \
      tar xf ${qt_string}-${qt_version}.tar.xz && \
    echo " done" && \
    echo -n "Extracting Qt5 WebEngine ${qt_donor}" && \
      tar xf ${qt_donor_string}-${qt_donor}.tar.xz && \
    echo " done" && \

    echo -n "Implanting Qt5 ${qt_donor}'s QtWebEngine.." && \
      rm -rf ${qt_string}-${qt_version}/qtwebengine/ && \
      mv ${qt_donor_string}-${qt_donor} ${qt_string}-${qt_version}/qtwebengine && \
    echo " done" && \

    # Remove the symbol versions for upward compatibility
    cd ${qt_string}-${qt_version} && \
      patch -d ${qt_string}-${qt_version} -p1 -i ../versiontag5120.patch && \
      patch -d ${qt_string}-${qt_version} -p1 -i ../qtwebengine599.patch && \
      patch -d ${qt_string}-${qt_version} -p1 -i ../qtwebengine_rpath.patch && \
      patch -d ${qt_string}-${qt_version} -p1 -i ../gcc_rpath.patch && \
      patch -d ${qt_string}-${qt_version} -p1 -i ../qt_no_append_rpath.path && \
    cd /build/ && \

    mkdir build && cd build && \
    ../${qt_string}-${qt_version}/configure -opensource -confirm-license \
                --prefix=$prefix/qt-${qt_version}-$suffix/lib \
                --libdir=$prefix/qt-${qt_version}-$suffix/lib \
                --bindir=$prefix/qt-${qt_version}-$suffix/lib/bin \
                --libexecdir=$prefix/qt-${qt_version}-$suffix/lib/libexec \
                --plugindir=$prefix/qt-${qt_version}-$suffix/lib/plugins \
                -shared                      \
                -c++std c++14                \
                -platform linux-g++-64       \
                -no-pch                      \
                -ssl                         \
                -fontconfig                  \
                -system-freetype             \
                -qt-zlib                     \
                -qt-libjpeg                  \
                -qt-libpng                   \
                -qt-xcb                      \
                -qt-xkbcommon-x11            \
                -nomake examples             \
                -nomake tests                \
                -no-sse4.1 -no-sse4.2        \
                -no-avx -no-avx2 -no-avx512  \
                -no-rpath                    \
                -no-dbus                     \
                -no-cups                     \
                -no-iconv                    \
                -no-gtk                      \
                -no-glib                     \
                -no-icu                      \
                -no-webrtc                   \
                -no-pepper-plugins           \
                -no-spellchecker             \
                -no-printing-and-pdf         \
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
                -skip qtremoteobjects        \
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

    make --jobs=$(nproc) && make install && \
    yum -y history undo last && \
    rm -rf /build/* && \

    # Don't carry gcc over, only Qt5
    rm -rf $prefix/gcc*

# We apparently lost those on the way
RUN echo "#include \"qwebenginesettings.h\"" > $prefix/qt-${qt_version}-$suffix/lib/include/QtWebEngineWidgets/QWebEngineSettings && \
    echo "#include \"qwebengineview.h\"" > $prefix/qt-${qt_version}-$suffix/lib/include/QtWebEngineWidgets/QWebEngineView

