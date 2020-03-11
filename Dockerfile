FROM sharpreflections/centos6-build-gcc:gcc-4.8.5
LABEL maintainer="dennis.brendel@sharpreflections.com"

ARG gcc=gcc-4.8.5
ARG qt_major=5.9
ARG qt_minor=.9
ARG qt_string=qt-everywhere-opensource-src

ARG prefix=/opt

WORKDIR /build/

ENV PATH=$prefix/$gcc/bin:$PATH
ENV LD_LIBRARY_PATH=$prefix/qt-${qt_major}${qt_minor}-icc19/lib:$prefix/$gcc/lib64::$LD_LIBRARY_PATH
ENV CC=icc
ENV CXX=icpc

COPY --from=sharpreflections/centos6-build-cmake $prefix $prefix

