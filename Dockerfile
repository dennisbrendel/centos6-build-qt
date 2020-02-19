FROM sharpreflections/centos6-build-gcc
LABEL maintainer="dennis.brendel@sharpreflections.com"

ARG gcc=gcc-5.5.0

ARG prefix=/opt

WORKDIR /build/

ENV PATH=$prefix/$gcc/bin:$PATH
ENV LD_LIBRARY_PATH=$prefix/$gcc/lib64:$LD_LIBRARY_PATH
ENV CC=/opt/$gcc/bin/gcc
ENV CXX=/opt/$gcc/bin/g++

RUN yum -y install xz glibc-headers glibc-devel mesa-libGL-devel mesa-libEGL-devel openssl-devel && \
    echo "Downlooading qt5: " && \
    curl --remote-name --location --progress-bar http://download.qt.io/official_releases/qt/5.14/5.14.1/single/qt-everywhere-src-5.14.1.tar.xz && \
    curl --remote-name --location --silent http://download.qt.io/official_releases/qt/5.14/5.14.1/single/md5sums.txt && \
    sed --in-place '/.*\.zip/d' md5sums.txt && \
    echo -n "Verifying file.." && md5sum --quiet --check md5sums.txt && echo " done" && \
    echo -n "Extracting qt5.. " && tar xf qt-everywhere-src-5.14.1.tar.xz && echo " done" && \
    mkdir build && cd build && \
    ../qt-everywhere-src-5.14.1/configure --prefix=/opt/qt-5.14.1-gcc   \
                -opensource -confirm-license \
                -shared                      \
                -c++std c++11                \
                -platform linux-g++-64       \
                -ssl                         \
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

COPY --from=sharpreflections/centos6-build-cmake $prefix $prefix
RUN yum -y install centos-release-scl && \
    yum -y install gperf python27 rh-ruby23 mesa-libGL-devel sqlite-devel libjpeg-turbo-devel zlib-devel \
                   libpng-devel libxml2-devel hyphen-devel libicu-devel && \
    git clone https://code.qt.io/qt/qtwebkit.git && \
    cd qtwebkit && \
    git checkout origin/5.212
RUN mkdir build && cd build && \
    sed --in-place 's/\(find_package(LibXml2\) 2.8.0/\1 2.7.0/' ../Source/cmake/OptionsQt.cmake && \
    # new in ICU 4.4, but we are only at 4.2. It's basically about character comparison which we don't care about
    sed --in-place 's/USEARCH_STANDARD_ELEMENT_COMPARISON/USEARCH_ON/'          ../Source/WebCore/editing/TextIterator.cpp && \
    sed --in-place 's/USEARCH_PATTERN_BASE_WEIGHT_IS_WILDCARD/USEARCH_ON/'      ../Source/WebCore/editing/TextIterator.cpp && \
    sed --in-place 's/(USearchAttribute)USEARCH_ELEMENT_COMPARISON/USEARCH_ON/' ../Source/WebCore/editing/TextIterator.cpp && \
    # Our ICU does not know that linebreak char, so purge it
    sed --in-place '/U_LB_CLOSE_PARENTHESIS/d'                    ../Source/WebCore/rendering/RenderRubyText.cpp && \
    # Something with overdrawing special characters which we most likely don't need to support
    sed --in-place '/UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_C/d' ../Source/WebCore/platform/graphics/FontCascade.cpp && \
    sed --in-place '/UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_D/d' ../Source/WebCore/platform/graphics/FontCascade.cpp && \
    sed --in-place '/UBLOCK_ENCLOSED_IDEOGRAPHIC_SUPPLEMENT/d'    ../Source/WebCore/platform/graphics/FontCascade.cpp && \
    sed --in-place '/UBLOCK_HANGUL_JAMO_EXTENDED_A/d'             ../Source/WebCore/platform/graphics/FontCascade.cpp && \
    sed --in-place '/UBLOCK_HANGUL_JAMO_EXTENDED_B/d'             ../Source/WebCore/platform/graphics/FontCascade.cpp && \

    source /opt/rh/rh-ruby23/enable && \
    /opt/cmake-3.11.4/bin/cmake .. -DPORT=Qt \
                                   -DQt5_DIR=/opt/qt-5.14.1/lib/cmake/Qt5 \
                                   -DCMAKE_INSTALL_PREFIX=/opt/qt-5.14.1  \
                                   -DCMAKE_PREFIX_PATH="/opt/rh/python27/root/usr/;/opt/rh/rh-ruby23/root/usr/" \
                                   -DENABLE_XSLT:BOOL=OFF                 \
                                   -DENABLE_OPENGL:BOOL=OFF               \
                                   -DENABLE_GEOLOCATION:BOOL=OFF          \
                                   -DENABLE_VIDEO:BOOL=OFF                \
                                   -DENABLE_LEGACY_WEB_AUDIO:BOOL=OFF     \
                                   -DENABLE_API_TESTS:BOOL=ON             \
                                   -DENABLE_CSS_GRID_LAYOUT:BOOL=OFF      \
                                   -DENABLE_GAMEPAD_DEPRECATED:BOOL=OFF   \
                                   -DENABLE_INSPECTOR_UI:BOOL=OFF         \
                                   -DENABLE_NETSCAPE_PLUGIN_API:BOOL=OFF  \
                                   -DENABLE_PRINT_SUPPORT:BOOL=OFF        \
                                   -DUSE_GSTREAMER:BOOL=OFF               \
                                   -DENABLE_INTL:BOOL=OFF                 \
                                   -DCMAKE_BUILD_TYPE=Release          && \
    make --jobs=$(nproc --all) && \
    make install

