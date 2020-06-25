#!/bin/bash

print_help() {
cat << EOF
Usage: $0 --icc19 <DIR> --license <DIR>

Options:
 --icc19 <DIR>    DIR is the root of the Intel Compiler installation
 --license <DIR>  DIR is the directory containing the compiler license file
 --podman         Use podman instead of docker
EOF

  exit 0
}

# Return the path to the requested runtime if called with argument,
# fall back to docker and podman if not
get_container_runtime() {
  if [ -n "$1" ]; then
    runtime=$(which "$1" 2>/dev/null)
    if [ $? -eq 0 ]; then
      echo "$runtime"
      exit 0
    fi
    (>&2 echo "Container runtime '"$1"' not found, falling back!")
  fi

  runtime=$(which docker 2>/dev/null)
  if [ $? -eq 0 ]; then
    echo "$runtime"
    exit 0
  fi
  runtime=$(which podman 2> /dev/null)
  if [ $? -ne 0]; then
    (>&2 echo "No container runtime found!")
    exit 1
  fi
  echo "$runtime"
}

# Pre-populate, should point to docker or to podman
runtime="$(get_container_runtime)"

while [ $# -gt 0 ]; do
  case "$1" in
    --icc19)   INTEL_DIR="$2"; shift;;
    --license) LIC_DIR="$2"; shift;;
    --podman)  runtime="$(get_container_runtime podman)";;
  esac
  shift
done

if [ -z "$INTEL_DIR" ] || [ -z "$LIC_DIR" ]; then
  print_help
fi


if [ -z "$runtime" ]; then
  (>&2 echo "Could not locate container runtime!")
  exit 2
fi

gcc=gcc-4.8.5
icc=icc-19.0
qt_major=5.9
qt_minor=.9
qt_version=${qt_major}${qt_minor}
qt_string=qt-everywhere-opensource-src
prefix=/opt
PATH=$prefix/qt-${qt_version}-icc19/bin:$prefix/$icc/bin:$prefix/$gcc/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/bin
LD_LIBRARY_PATH=$prefix/$icc/compilers_and_libraries/linux/lib/intel64_lin/:$prefix/$gcc/lib64

mounts="$INTEL_DIR:/opt/icc-19.0
        $LIC_DIR:/root/Licenses"

envs="gcc=$gcc
      icc=$icc
      qt_major=$qt_major
      qt_minor=$qt_minor
      qt_version=$qt_version
      qt_string=$qt_string
      prefix=$prefix
      PATH=$PATH
      LD_LIBRARY_PATH=$LD_LIBRARY_PATH
      CC=icc
      CXX=icpc"

for mount in $mounts; do
  MOUNT="$MOUNT --volume $mount"
done

for env in $envs; do
  ENV="$ENV --env $env"
done


$runtime run $ENV $MOUNT --interactive --tty --name centos6-build-qt-icc19 \
             sharpreflections/centos6-build-qt:qt-${qt_version}_icc-19.0_base bash -c "
set -e

yum -y install centos-release-scl
yum -y install python27 xz glibc-headers glibc-devel mesa-libGL-devel mesa-libEGL-devel openssl-devel \
               fontconfig-devel dbus-devel libXcomposite-devel libXcursor-devel libXi-devel libXrandr-devel \
               libXtst-devel gperf expat-devel

source /opt/rh/python27/enable

cd /build
echo \"Downloading Qt5 ${qt_version}:\"
  curl --remote-name --location --progress-bar http://download.qt.io/official_releases/qt/${qt_major}/${qt_version}/single/${qt_string}-${qt_version}.tar.xz
  curl --remote-name --location --silent http://download.qt.io/official_releases/qt/${qt_major}/${qt_version}/single/md5sums.txt
  sed --in-place '/.*\.zip/d' md5sums.txt

echo -n \"Verifying file..\"
  md5sum --quiet --check md5sums.txt
echo \" done\"

echo -n \"Extracting qt5.. \"
  tar xf ${qt_string}-${qt_version}.tar.xz
echo \" done\"

echo -n \"Patching qt5 for compilation with Intel Compiler 19.0..\"
  cd ${qt_string}-${qt_version}
  patch -p1 -i ../intel19.patch
  patch -p1 -i ../versiontag599.patch
  cd /build/
echo \" done\"

mkdir build && cd build 
../${qt_string}-${qt_version}/configure --prefix=${prefix}/qt-${qt_version}-icc19 \
                -opensource -confirm-license \
                -shared                      \
                -c++std c++11                \
                -platform linux-icc-64       \
                -no-pch                      \
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
                -no-webrtc                   \
                -no-pepper-plugins           \
                -no-spellchecker             \
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
                -skip qtwinextras
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

# Only two build jobs because the Intel Compiler 19.0 tends to segfault sometimes with many jobs
make --jobs=$(nproc)
make install

yum -y history undo last
rm -rf /build/*

# Don't carry gcc over, only Qt5
rm -rf $prefix/gcc*

# Fix private include dir bug
sed --in-place 's:\(set(Qt5Gui_PRIVATE_INCLUDE_DIRS\) \"\"):\1 \"\$\{_qt5Gui_install_prefix\}/include/QtGui/\$\{Qt5Gui_VERSION_STRING\}\" \"\$\{_qt5Gui_install_prefix\}/include/QtGui/\$\{Qt5Gui_VERSION_STRING\}/QtGui\"):' $prefix/qt-${qt_version}-icc19/lib/cmake/Qt5Gui/Qt5GuiConfig.cmake
￼sed --in-place 's:\(set(Qt5Core_PRIVATE_INCLUDE_DIRS\) \"\"):\1 \"\$\{_qt5Core_install_prefix\}/include/QtCore/\$\{Qt5Core_VERSION_STRING\}\" \"\$\{_qt5Core_install_prefix\}/include/QtCore/\$\{Qt5Core_VERSION_STRING\}/QtCore\"):' $prefix/qt-${qt_version}-icc19/lib/cmake/Qt5Core/Qt5CoreConfig.cmake
"

$runtime commit centos6-build-qt-icc19 sharpreflections/centos6-build-qt:qt-5.9.9_icc-19.0

