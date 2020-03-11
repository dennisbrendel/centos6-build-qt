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

RUN yum -y install xz glibc-headers glibc-devel mesa-libGL-devel mesa-libEGL-devel openssl-devel fontconfig-devel && \
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
                -no-rpath                    \
                -no-cups                     \
                -no-iconv                    \
                -no-dbus                     \
                -no-gtk                      \
                -no-glib                  && \
    make --jobs=$(nproc --all) && make install   && \
    yum -y history undo last && \
    yum clean all && \
    cd /build && rm -rf *

ENV LD_LIBRARY_PATH=$prefix/qt-${qt_major}${qt_minor}-gcc485/lib:$LD_LIBRARY_PATH
COPY --from=sharpreflections/centos6-build-cmake $prefix $prefix
RUN yum -y install centos-release-scl && \
    yum -y install gperf python27 rh-ruby23 mesa-libGL-devel sqlite-devel libjpeg-turbo-devel zlib-devel \
                   libpng-devel libxml2-devel hyphen-devel libicu-devel libXcomposite-devel libXrender-devel && \
    git clone https://code.qt.io/qt/qtwebkit.git && \
    cd qtwebkit && \
    git checkout --track origin/5.212 && \
    mkdir /build/qtwebkit/build && cd /build/qtwebkit/build && \
    sed --in-place 's/\(find_package(LibXml2\) 2.8.0/\1 2.7.0/' ../Source/cmake/OptionsQt.cmake && \
    # new in ICU 4.4, but we are only at 4.2. It's basically about character comparison which we don't care about
    sed --in-place 's/USEARCH_STANDARD_ELEMENT_COMPARISON/USEARCH_ON/'          ../Source/WebCore/editing/TextIterator.cpp && \
    sed --in-place 's/USEARCH_PATTERN_BASE_WEIGHT_IS_WILDCARD/USEARCH_ON/'      ../Source/WebCore/editing/TextIterator.cpp && \
    sed --in-place 's/USEARCH_ELEMENT_COMPARISON/(USearchAttribute)USEARCH_ON/' ../Source/WebCore/editing/TextIterator.cpp && \
    # Our ICU does not know that linebreak char, so purge it
    sed --in-place '/U_LB_CLOSE_PARENTHESIS/d'                    ../Source/WebCore/rendering/RenderRubyText.cpp && \
    # Something with overdrawing special characters which we most likely don't need to support
    sed --in-place '/UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_C/d' ../Source/WebCore/platform/graphics/FontCascade.cpp && \
    sed --in-place '/UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_D/d' ../Source/WebCore/platform/graphics/FontCascade.cpp && \
    sed --in-place '/UBLOCK_ENCLOSED_IDEOGRAPHIC_SUPPLEMENT/d'    ../Source/WebCore/platform/graphics/FontCascade.cpp && \
    sed --in-place '/UBLOCK_HANGUL_JAMO_EXTENDED_A/d'             ../Source/WebCore/platform/graphics/FontCascade.cpp && \
    sed --in-place '/UBLOCK_HANGUL_JAMO_EXTENDED_B/d'             ../Source/WebCore/platform/graphics/FontCascade.cpp && \
    # Some include is missing
    sed --in-place '/Modules\/mediasession$/aModules\/mediasource/' ../Source/WebCore/CMakeLists.txt && \
    # Added with ICU 4.6 - number format symbols
    sed --in-place '/UNUM_ONE_DIGIT_SYMBOL/d'   ../Source/WebCore/platform/text/LocaleICU.cpp && \
    sed --in-place '/UNUM_TWO_DIGIT_SYMBOL/d'   ../Source/WebCore/platform/text/LocaleICU.cpp && \
    sed --in-place '/UNUM_THREE_DIGIT_SYMBOL/d' ../Source/WebCore/platform/text/LocaleICU.cpp && \
    sed --in-place '/UNUM_FOUR_DIGIT_SYMBOL/d'  ../Source/WebCore/platform/text/LocaleICU.cpp && \
    sed --in-place '/UNUM_FIVE_DIGIT_SYMBOL/d'  ../Source/WebCore/platform/text/LocaleICU.cpp && \
    sed --in-place '/UNUM_SIX_DIGIT_SYMBOL/d'   ../Source/WebCore/platform/text/LocaleICU.cpp && \
    sed --in-place '/UNUM_SEVEN_DIGIT_SYMBOL/d' ../Source/WebCore/platform/text/LocaleICU.cpp && \
    sed --in-place '/UNUM_EIGHT_DIGIT_SYMBOL/d' ../Source/WebCore/platform/text/LocaleICU.cpp && \
    sed --in-place '/UNUM_NINE_DIGIT_SYMBOL/d'  ../Source/WebCore/platform/text/LocaleICU.cpp && \
    # Fix Qt private include paths
    sed --in-place 's:\(set(Qt5Gui_PRIVATE_INCLUDE_DIRS\) ""):\1 "${_qt5Gui_install_prefix}/include/QtGui/${Qt5Gui_VERSION_STRING}" "${_qt5Gui_install_prefix}/include/QtGui/${Qt5Gui_VERSION_STRING}/QtGui"):' $prefix/qt-${qt_major}${qt_minor}-gcc485/lib/cmake/Qt5Gui/Qt5GuiConfig.cmake && \
    sed --in-place 's:\(set(Qt5Core_PRIVATE_INCLUDE_DIRS\) ""):\1 "${_qt5Core_install_prefix}/include/QtCore/${Qt5Core_VERSION_STRING}" "${_qt5Core_install_prefix}/include/QtCore/${Qt5Core_VERSION_STRING}/QtCore"):' $prefix/qt-${qt_major}${qt_minor}-gcc485/lib/cmake/Qt5Core/Qt5CoreConfig.cmake && \

    source /opt/rh/rh-ruby23/enable && \
    source /opt/rh/python27/enable && \
    /opt/cmake-3.11.4/bin/cmake .. -DPORT=Qt \
                                   -DQt5_DIR=/opt/qt-${qt_major}${qt_minor}-gcc485/lib/cmake/Qt5 \
                                   -DCMAKE_INSTALL_PREFIX=/opt/qt-${qt_major}${qt_minor}-gcc485 \
                                   -DCMAKE_PREFIX_PATH="/opt/rh/python27/root/usr/;/opt/rh/rh-ruby23/root/usr/" \
                                   -DENABLE_ACCELERATED_2D_CANVAS:BOOL=OFF\
                                   -DENABLE_API_TESTS:BOOL=OFF            \
                                   -DENABLE_CSS_GRID_LAYOUT:BOOL=OFF      \
                                   -DENABLE_DATABASE_PROCESS:BOOL=OFF     \
                                   -DENABLE_DEVICE_ORIENTATION:BOOL=OFF   \
                                   -DENABLE_DRAG_SUPPORT:BOOL=OFF         \
                                   -DENABLE_FULLSCREEN_API:BOOL=OFF       \
                                   -DENABLE_GAMEPAD_DEPRECATED:BOOL=OFF   \
                                   -DENABLE_GEOLOCATION:BOOL=OFF          \
                                   -DENABLE_ICONDATABASE:BOOL=OFF         \
                                   -DENABLE_INDEXED_DATABASE:BOOL=OFF     \
                                   -DENABLE_INSPECTOR_UI:BOOL=OFF         \
                                   -DENABLE_JIT:BOOL=OFF                  \
                                   -DENABLE_LEGACY_WEB_AUDIO:BOOL=OFF     \
                                   -DENABLE_NETSCAPE_PLUGIN_API:BOOL=OFF  \
                                   -DENABLE_OPENGL:BOOL=OFF               \
                                   -DENABLE_PRINT_SUPPORT:BOOL=OFF        \
                                   -DENABLE_SAMPLING_PROFILER:BOOL=OFF    \
                                   -DENABLE_SPELLCHECK:BOOL=OFF           \
                                   -DENABLE_TOUCH_EVENTS:BOOL=OFF         \
                                   -DENABLE_VIDEO:BOOL=OFF                \
                                   -DENABLE_WEBKIT2:BOOL=OFF              \
                                   -DENABLE_XSLT:BOOL=OFF                 \
                                   -DUSE_GSTREAMER:BOOL=OFF               \
                                   -DUSE_LIBHYPHEN:BOOL=OFF               \
                                   -DENABLE_INTL:BOOL=OFF                 \
                                   -DUSE_SYSTEM_MALLOC:BOOL=ON            \
                                   -DUSE_WOFF2:BOOL=OFF                   \
                                   -DCMAKE_BUILD_TYPE=Release          && \
    make --jobs=$(nproc --all) && \
    make install && rm -rf /build/*

