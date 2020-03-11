# centos6-build-qt:qt-5.9.9\_icc-19.0\_base

CentOS6 based image that is the base for building Qt5 and QtWebkit using the
Intel Compiler 19.0

Use the supplied *build\_qt\_qtwebkit\_icc19.sh* to compile a new Qt 5.9.9 and
QtWebkit using the Intel Compiler. It will use docker by default, but you can
also set it to use podman.

The result is the image **sharpreflections/centos6-build-qt:qt-5.9.9\_icc-19.0**
This image should then be pushed to docker.io and a rebuild of **centos6-build**
should be triggered, so it includes the latest build

1. Make sure that using the Dockerfile of this repo an image with the following
  name and tag is created:
  **sharpreflections/centos6-build-qt:qt-5.9.9_icc-19.0_base**
  - docker.io is set up to do that (2020-03-11)
2. Call *build\_qt\_qtwebkit\_icc19.sh* which _should_ generate
  **sharpreflections/centos6-build-qt:qt-5.9.9\_icc-19.0**
3. Verify the content
```
docker run --rm -it sharpreflections/centos6-build-qt:qt-5.9.9_icc-19.0 bash
```
4. Push the image to docker.io using
```
docker push locahost/sharpreflections/centos6-build-qt:qt-5.9.9_icc-19.0 \
            docker.io/sharpreflections/centos6-build-qt:qt-5.9.9_icc-19.0
```
