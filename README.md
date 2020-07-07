# centos6-build-qt:qt-5.12.0\_icc-19.0

CentOS6 based image for compiling Qt with some modules like QtWebEngine using
the Intel Compiler 19.0

1. Clone this repo and enter the respective directory
2. Build a new image:
```
docker build . --volume /PATH-TO-intel_parallel_studio_xe_2019_Update_5/:/opt/icc-19.0 \
               --volume /PATH-TO-Compilers/licenses/:/root/Licenses \
               --tag sharpreflections/centos6-build-qt:qt-5.12.0_icc-19.0
```
3. Verify the content
```
docker run --rm -it sharpreflections/centos6-build-qt:qt-5.12.0_icc-19.0 bash
```
4. Push the image to docker.io using
```
docker push localhost/sharpreflections/centos6-build-qt:qt-5.12.0_icc-19.0 \
            docker.io/sharpreflections/centos6-build-qt:qt-5.12.0_icc-19.0
```
