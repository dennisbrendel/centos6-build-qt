#!/bin/sh

icc=icc-19.0
qt_major=5.12
qt_minor=.0
qt_version=${qt_major}${qt_minor}
qt_string=qt-everywhere-src
qt_donor_major=5.9
qt_donor_minor=.9
qt_donor=${qt_donor_major}${qt_donor_minor}
qt_donor_string=qtwebengine-opensource-src
prefix=/opt
suffix=${icc}


set -x
set -e
[ -f ${qt_string}-${qt_version}.tar.xz ] || \
curl --remote-name --location --progress-bar http://download.qt.io/official_releases/qt/${qt_major}/${qt_version}/single/${qt_string}-${qt_version}.tar.xz
[ -f md5sums.txt ] || \
curl --remote-name --location --silent http://download.qt.io/official_releases/qt/${qt_major}/${qt_version}/single/md5sums.txt
sed --in-place '/.*\.zip/d' md5sums.txt
md5sum --quiet --check md5sums.txt
rm md5sums.txt

[ -f ${qt_donor_string}-${qt_donor}.tar.xz ] || \
curl --remote-name --location --progress-bar http://download.qt.io/official_releases/qt/${qt_donor_major}/${qt_donor}/submodules/${qt_donor_string}-${qt_donor}.tar.xz
curl --remote-name --location --silent http://download.qt.io/official_releases/qt/${qt_donor_major}/${qt_donor}/submodules/md5sums.txt
grep qtwebengine md5sums.txt > md5sums.txt.new
mv md5sums.txt.new md5sums.txt
sed --in-place '/.*\.zip/d' md5sums.txt
md5sum --quiet --check md5sums.txt
rm md5sums.txt

# start fresh
[ -d ${qt_string}-${qt_version} ] && rm -r ${qt_string}-${qt_version}
[ -d ${qt_donor_string}-${qt_donor} ] && rm -r ${qt_donor_string}-${qt_donor}

tar --exclude=qtwebengine -xf ${qt_string}-${qt_version}.tar.xz
tar xf ${qt_donor_string}-${qt_donor}.tar.xz
#rm -rf ${qt_string}-${qt_version}/qtwebengine/
mv ${qt_donor_string}-${qt_donor} ${qt_string}-${qt_version}/qtwebengine

patch -d ${qt_string}-${qt_version} -p1 -i ../no-versiontag5120.patch
patch -d ${qt_string}-${qt_version} -p1 -i ../intel19.patch
patch -d ${qt_string}-${qt_version} -p1 -i ../intel19_rpath.patch
patch -d ${qt_string}-${qt_version} -p1 -i ../intel19_qtwebengine599.patch
patch -d ${qt_string}-${qt_version} -p1 -i ../qtwebengine_rpath.patch
patch -d ${qt_string}-${qt_version} -p1 -i ../qt_no_append_rpath.patch
patch -d ${qt_string}-${qt_version}/qtbase/ -p1 -i ../../DND_QTBUG-72844_52e0d9e.patch
patch -d ${qt_string}-${qt_version}/qtwebengine/ -p1 -i ../../qtwebengine_suppress-icu-datapath-warning.patch     
patch -d ${qt_string}-${qt_version}/qtwebengine/ -p1 -i ../../qtwebengine_suppress-locales-datapath-warning.patch
patch -d ${qt_string}-${qt_version}/qtwebengine/ -p1 -i ../../qtwebengine_suppress-resources-datapath-warning.patch

tar cJpf Qt-${qt_version}_sharpreflections.tar.xz ${qt_string}-${qt_version}
